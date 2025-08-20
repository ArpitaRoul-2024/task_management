const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const cors = require('cors');
const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');
const http = require('http');
const socketIO = require('socket.io');

const app = express();
const port = process.env.PORT || 3000;

// Create HTTP server
const server = http.createServer(app);
const io = socketIO(server, {
  cors: {
    origin: ['http://localhost:3000', 'https://task-management-9gaz.onrender.com', 'https://your-flutter-app-url'],
    methods: ['GET', 'POST'],
    credentials: true,
  },
});

// Supabase setup
const supabaseUrl = 'https://ygwvugengpvtjvohtbjr.supabase.co';
const supabaseKey = process.env.SUPABASE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlnd3Z1Z2VuZ3B2dGp2b2h0YmpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE0NDgxOTksImV4cCI6MjA2NzAyNDE5OX0.4g_talCOg-mxC47QT20Z-4wfRicnpb38wBNC6QX3CYM';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlnd3Z1Z2VuZ3B2dGp2b2h0YmpyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTQ0ODE5OSwiZXhwIjoyMDY3MDI0MTk5fQ.fiC0K1fJVBOFiZ18P3bObx7bGn52IB6VrReP5SaGCG0';
const supabase = createClient(supabaseUrl, supabaseKey);
const supabaseService = createClient(supabaseUrl, supabaseServiceKey);

// Secret key for token signing
const JWT_SECRET = process.env.JWT_SECRET || 'YPp/oHPTijtJDWKrZynQWEWvzA+9WzPf0uKQMUa0oH+cacU19kU1TQB/4Y8EStxm9fgBkbyy6FopHRr9NsMMqQ==';

// Store connected users (userId: socketId)
const connectedUsers = new Map();

app.use(cors());
app.use(express.json());

// Middleware to authenticate user
const authenticateUser = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    console.log('No valid token provided at', new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }));
    return res.status(401).json({ error: 'Unauthorized: No token provided' });
  }

  const token = authHeader.split(' ')[1];
  try {
    const [headerEncoded, payloadEncoded, signature] = token.split('.');
    if (!headerEncoded || !payloadEncoded || !signature) {
      throw new Error('Invalid token format');
    }
    const payload = JSON.parse(Buffer.from(payloadEncoded.replace(/=+$/, ''), 'base64').toString('utf-8'));
    if (payload.exp && payload.exp < Date.now() / 1000) {
      throw new Error('Token expired');
    }
    const expectedSignature = crypto
      .createHmac('sha256', JWT_SECRET)
      .update(`${headerEncoded}.${payloadEncoded}`)
      .digest('base64')
      .replace(/=+$/, '');
    if (signature !== expectedSignature) {
      throw new Error('Invalid token signature');
    }
    req.user = { id: payload.sub, role: payload.role };
    next();
  } catch (err) {
    console.log('Token validation error at', new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }), ':', err.message);
    return res.status(401).json({ error: 'Unauthorized: Invalid token' });
  }
};

// Global error handler
app.use((err, req, res, next) => {
  console.error('Unhandled error at', new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }), ':', err.message);
  res.status(err.status || 500).json({ error: err.message || 'Internal server error' });
});

// Socket.IO connection handler
io.on('connection', (socket) => {
  console.log('New client connected:', socket.id);

  socket.on('authenticate', (token) => {
    try {
      const [headerEncoded, payloadEncoded] = token.split('.');
      const payload = JSON.parse(Buffer.from(payloadEncoded.replace(/=+$/, ''), 'base64').toString('utf-8'));
      const userId = payload.sub;
      connectedUsers.set(userId, socket.id);
      socket.userId = userId;
      console.log(`User ${userId} authenticated with socket ${socket.id}`);
    } catch (err) {
      console.log('Authentication error:', err.message);
      socket.emit('authError', 'Invalid token');
      socket.disconnect(true);
    }
  });

  socket.on('disconnect', () => {
    if (socket.userId) {
      connectedUsers.delete(socket.userId);
      console.log(`User ${socket.userId} disconnected`);
    }
  });
});

// Sign Up endpoint
app.post('/api/signup', async (req, res) => {
  const { name, email, password } = req.body;

  if (!name || !email || !password) {
    return res.status(400).json({ error: 'Name, email, and password are required' });
  }

  try {
    const { data: existingUser, error: checkError } = await supabase
      .from('users')
      .select('id')
      .eq('email', email)
      .maybeSingle();

    if (checkError) throw checkError;
    if (existingUser) {
      return res.status(400).json({ error: 'Email already exists' });
    }

    const hashedPassword = crypto.createHash('sha256').update(password).digest('hex');
    const userId = uuidv4();
    const { data, error } = await supabaseService
      .from('users')
      .insert([{ id: userId, name, email, password: hashedPassword, role: 'User' }])
      .select()
      .single();

    if (error) throw error;

    const payload = {
      sub: data.id,
      email: data.email,
      role: data.role,
      exp: Math.floor(Date.now() / 1000) + 24 * 60 * 60,
    };
    const header = { alg: 'HS256', typ: 'JWT' };
    const headerEncoded = Buffer.from(JSON.stringify(header)).toString('base64');
    const payloadEncoded = Buffer.from(JSON.stringify(payload)).toString('base64');
    const signature = crypto
      .createHmac('sha256', JWT_SECRET)
      .update(`${headerEncoded}.${payloadEncoded}`)
      .digest('base64')
      .replace(/=+$/, '');
    const token = `${headerEncoded}.${payloadEncoded}.${signature}`;

    res.status(201).json({
      token,
      user: { id: data.id, name: data.name, email: data.email, role: data.role },
    });
  } catch (err) {
    console.error('Error during signup at', new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }), ':', err.message);
    res.status(500).json({ error: 'Failed to sign up' });
  }
});

// Login endpoint
app.post('/api/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }

  try {
    const hashedPassword = crypto.createHash('sha256').update(password).digest('hex');
    const { data, error } = await supabase
      .from('users')
      .select('id, name, email, role')
      .eq('email', email)
      .eq('password', hashedPassword)
      .single();

    if (error || !data) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const payload = {
      sub: data.id,
      email: data.email,
      role: data.role || 'User',
      exp: Math.floor(Date.now() / 1000) + 24 * 60 * 60,
    };
    const header = { alg: 'HS256', typ: 'JWT' };
    const headerEncoded = Buffer.from(JSON.stringify(header)).toString('base64');
    const payloadEncoded = Buffer.from(JSON.stringify(payload)).toString('base64');
    const signature = crypto
      .createHmac('sha256', JWT_SECRET)
      .update(`${headerEncoded}.${payloadEncoded}`)
      .digest('base64')
      .replace(/=+$/, '');
    const token = `${headerEncoded}.${payloadEncoded}.${signature}`;

    res.json({ token, user: { id: data.id, name: data.name, email: data.email, role: data.role } });
  } catch (err) {
    console.error('Error during login at', new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }), ':', err.message);
    res.status(500).json({ error: 'Failed to login' });
  }
});

// Check Auth endpoint for auto-login
app.get('/api/check-auth', authenticateUser, async (req, res) => {
  try {
    const { id, role } = req.user;
    const { data, error } = await supabaseService
      .from('users')
      .select('id, name, email, role')
      .eq('id', id)
      .single();

    if (error || !data) {
      throw new Error('User not found');
    }

    res.json({
      token: req.headers.authorization.split(' ')[1],
      user: { id: data.id, name: data.name, email: data.email, role: data.role },
    });
  } catch (err) {
    console.error('Error checking auth at', new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }), ':', err.message);
    res.status(401).json({ error: 'Unauthorized: Invalid token' });
  }
});

// Users endpoint
app.get('/api/users', authenticateUser, async (req, res) => {
  try {
    const { data, error } = await supabaseService
      .from('users')
      .select('id, name, email, role');

    if (error) throw error;

    res.json(data || []);
  } catch (err) {
    console.error('Error fetching users at', new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }), ':', err.message);
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// Tasks endpoint
app.get('/api/tasks', authenticateUser, async (req, res) => {
  try {
    let query = supabaseService
      .from('task')
      .select(`
        id,
        title,
        description,
        due_date,
        priority,
        status,
        created_by,
        assigned_to,
        created_at,
        task_attachments(id, task_id, file_url, file_name)
      `)
      .order('created_at', { ascending: false });

    if (req.user.role !== 'Admin') {
      query = query.or(`created_by.eq.${req.user.id},assigned_to.eq.${req.user.id}`);
    }

    const { data, error } = await query;

    if (error) throw error;

    res.json(data || []);
  } catch (err) {
    console.error('Error fetching tasks at', new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }), ':', err.message);
    res.status(500).json({ error: 'Failed to fetch tasks' });
  }
});

// Create task
app.post('/api/tasks', authenticateUser, async (req, res) => {
  const { title, description, due_date, priority, status, assigned_to } = req.body;
  const created_by = req.user.id;

  if (!title) {
    return res.status(400).json({ error: 'Title is required' });
  }

  try {
    const { data, error } = await supabaseService
      .from('task')
      .insert([{ id: uuidv4(), title, description, due_date, priority, status, created_by, assigned_to }])
      .select()
      .single();

    if (error) throw error;
    res.status(201).json(data);
  } catch (err) {
    console.error('Error creating task at', new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }), ':', err.message);
    res.status(500).json({ error: 'Failed to create task' });
  }
});

// Update task
app.put('/api/tasks/:id', authenticateUser, async (req, res) => {
  const { id } = req.params;
  const { title, description, due_date, priority, status, assigned_to } = req.body;

  try {
    const { data: task, error: fetchError } = await supabaseService
      .from('task')
      .select('created_by, assigned_to')
      .eq('id', id)
      .single();

    if (fetchError || !task) {
      return res.status(404).json({ error: 'Task not found' });
    }

    if (task.created_by !== req.user.id && task.assigned_to !== req.user.id && req.user.role !== 'Admin') {
      return res.status(403).json({ error: 'Forbidden: You can only update tasks you created, are assigned to, or as Admin' });
    }

    const { data, error } = await supabaseService
      .from('task')
      .update({ title, description, due_date, priority, status, assigned_to })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    res.json(data);
  } catch (err) {
    console.error('Error updating task at', new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }), ':', err.message);
    res.status(500).json({ error: 'Failed to update task' });
  }
});

// Delete task
app.delete('/api/tasks/:id', authenticateUser, async (req, res) => {
  const { id } = req.params;

  try {
    const { data: task, error: fetchError } = await supabaseService
      .from('task')
      .select('created_by, assigned_to')
      .eq('id', id)
      .single();

    if (fetchError || !task) {
      return res.status(404).json({ error: 'Task not found' });
    }

    if (task.created_by !== req.user.id && task.assigned_to !== req.user.id && req.user.role !== 'Admin') {
      return res.status(403).json({ error: 'Forbidden: You can only delete tasks you created, are assigned to, or as Admin' });
    }

    const { error } = await supabaseService
      .from('task')
      .delete()
      .eq('id', id);

    if (error) throw error;
    res.status(200).json({ message: 'Task deleted' });
  } catch (err) {
    console.error('Error deleting task at', new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }), ':', err.message);
    res.status(500).json({ error: 'Failed to delete task' });
  }
});

// Add attachment
app.post('/api/tasks/:taskId/attachments', authenticateUser, async (req, res) => {
  const { taskId } = req.params;
  const { file_url, file_name } = req.body;

  if (!file_url || !file_name) {
    return res.status(400).json({ error: 'File URL and name are required' });
  }

  try {
    const { data: task, error: fetchError } = await supabaseService
      .from('task')
      .select('created_by, assigned_to')
      .eq('id', taskId)
      .single();

    if (fetchError || !task) {
      return res.status(404).json({ error: 'Task not found' });
    }

    if (task.created_by !== req.user.id && task.assigned_to !== req.user.id && req.user.role !== 'Admin') {
      return res.status(403).json({ error: 'Forbidden: You can only add attachments to tasks you created, are assigned to, or as Admin' });
    }

    const { data, error } = await supabaseService
      .from('task_attachments')
      .insert([{ id: uuidv4(), task_id: taskId, file_url, file_name }])
      .select()
      .single();

    if (error) throw error;
    res.status(201).json(data);
  } catch (err) {
    console.error('Error adding attachment at', new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }), ':', err.message);
    res.status(500).json({ error: 'Failed to add attachment' });
  }
});

// Send chat message
app.post('/api/chat', authenticateUser, async (req, res) => {
  const { receiver_id, message } = req.body;
  const sender_id = req.user.id;

  if (!receiver_id || !message) {
    return res.status(400).json({ error: 'Receiver ID and message are required' });
  }

  try {
    const { data: receiver, error: receiverError } = await supabaseService
      .from('users')
      .select('id')
      .eq('id', receiver_id)
      .maybeSingle();

    if (receiverError || !receiver) {
      return res.status(404).json({ error: 'Receiver not found' });
    }

    // Fetch sender's name
    const { data: sender, error: senderError } = await supabaseService
      .from('users')
      .select('name')
      .eq('id', sender_id)
      .single();

    if (senderError || !sender) {
      throw new Error('Sender not found');
    }

    const messageData = {
      id: uuidv4(),
      sender_id,
      receiver_id,
      message,
      created_at: new Date().toISOString(),
      is_read: false,
      sender_name: sender.name,
    };

    const { data, error } = await supabaseService
      .from('chat')
      .insert([messageData])
      .select()
      .single();

    if (error) throw error;

    // Emit to both receiver and sender
    const receiverSocketId = connectedUsers.get(receiver_id);
    if (receiverSocketId) {
      io.to(receiverSocketId).emit('newMessage', data);
      console.log(`Emitted new message to ${receiver_id} (socket: ${receiverSocketId})`);
    } else {
      console.log(`No active connection for receiver ${receiver_id}`);
    }

    const senderSocketId = connectedUsers.get(sender_id);
    if (senderSocketId) {
      io.to(senderSocketId).emit('newMessage', data);
      console.log(`Emitted new message to ${sender_id} (socket: ${senderSocketId})`);
    }

    res.status(201).json(data);
  } catch (err) {
    console.error('Error sending message at', new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }), ':', err.message);
    res.status(500).json({ error: 'Failed to send message' });
  }
});

// Fetch chat messages
app.get('/api/chat', authenticateUser, async (req, res) => {
  const { sender_id, receiver_id } = req.query;

  if (!sender_id || !receiver_id) {
    return res.status(400).json({ error: 'Sender ID and receiver ID are required' });
  }

  try {
    const userId = req.user.id;
    if (sender_id !== userId && receiver_id !== userId) {
      return res.status(403).json({ error: 'Forbidden: You can only view your own conversations' });
    }

    const { data, error } = await supabaseService
      .from('chat')
      .select('*, users!chat_sender_id_fkey(name)')
      .or(`(sender_id.eq.${sender_id},receiver_id.eq.${receiver_id}),(sender_id.eq.${receiver_id},receiver_id.eq.${sender_id})`)
      .order('created_at', { ascending: true });

    if (error) throw error;

    // Map data to include sender_name
    const messages = data.map((msg) => ({
      ...msg,
      sender_name: msg.users?.name || 'Unknown',
    }));

    res.json(messages || []);
  } catch (err) {
    console.error('Error fetching messages at', new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }), ':', err.message);
    res.status(500).json({ error: 'Failed to fetch messages' });
  }
});

// Mark messages as read
app.post('/api/chat/read', authenticateUser, async (req, res) => {
  const { sender_id, receiver_id } = req.body;

  if (!sender_id || !receiver_id) {
    return res.status(400).json({ error: 'Sender ID and receiver ID are required' });
  }

  try {
    const userId = req.user.id;
    if (receiver_id !== userId) {
      return res.status(403).json({ error: 'Forbidden: You can only mark your own messages as read' });
    }

    const { error } = await supabaseService
      .from('chat')
      .update({ is_read: true })
      .eq('sender_id', sender_id)
      .eq('receiver_id', receiver_id)
      .eq('is_read', false);

    if (error) throw error;

    res.status(200).json({ message: 'Messages marked as read' });
  } catch (err) {
    console.error('Error marking messages as read at', new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }), ':', err.message);
    res.status(500).json({ error: 'Failed to mark messages as read' });
  }
});

// Fetch unread messages count
app.get('/api/chat/unread', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const { data, error } = await supabaseService
      .from('chat')
      .select('id')
      .eq('receiver_id', userId)
      .eq('is_read', false);

    if (error) throw error;

    res.json({ count: data.length });
  } catch (err) {
    console.error('Error fetching unread messages at', new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }), ':', err.message);
    res.status(500).json({ error: 'Failed to fetch unread messages' });
  }
});

// Start the server
server.listen(port, () => {
  console.log(`Server running on port ${port}`);
});