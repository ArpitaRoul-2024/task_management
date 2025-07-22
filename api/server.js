const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const cors = require('cors');
const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');

const app = express();
const port = 3000;

// Supabase setup
const supabaseUrl = 'https://ygwvugengpvtjvohtbjr.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlnd3Z1Z2VuZ3B2dGp2b2h0YmpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE0NDgxOTksImV4cCI6MjA2NzAyNDE5OX0.4g_talCOg-mxC47QT20Z-4wfRicnpb38wBNC6QX3CYM';
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlnd3Z1Z2VuZ3B2dGp2b2h0YmpyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTQ0ODE5OSwiZXhwIjoyMDY3MDI0MTk5fQ.fiC0K1fJVBOFiZ18P3bObx7bGn52IB6VrReP5SaGCG0';
const supabase = createClient(supabaseUrl, supabaseKey);
const supabaseService = createClient(supabaseUrl, supabaseServiceKey);

// Secret key for token signing
const JWT_SECRET = 'YPp/oHPTijtJDWKrZynQWEWvzA+9WzPf0uKQMUa0oH+cacU19kU1TQB/4Y8EStxm9fgBkbyy6FopHRr9NsMMqQ==';

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
    const payload = JSON.parse(Buffer.from(payloadEncoded, 'base64').toString('utf-8'));
    if (payload.exp && payload.exp < Date.now() / 1000) {
      throw new Error('Token expired');
    }
    req.user = { id: payload.sub, role: payload.role };
    next();
  } catch (err) {
    console.log('Token validation error at', new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }), ':', err.message);
    return res.status(401).json({ error: 'Unauthorized: Invalid token' });
  }
};

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

    const userId = uuidv4();
    const { data, error } = await supabaseService
      .from('users')
      .insert([{
        id: userId,
        name,
        email,
        password,
        role: 'User',
      }])
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
    const headerEncoded = Buffer.from(JSON.stringify(header)).toString('base64').replace(/=+$/, '');
    const payloadEncoded = Buffer.from(JSON.stringify(payload)).toString('base64').replace(/=+$/, '');
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
    const { data, error } = await supabase
      .from('users')
      .select('id, name, email, role')
      .eq('email', email)
      .eq('password', password)
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
    const headerEncoded = Buffer.from(JSON.stringify(header)).toString('base64').replace(/=+$/, '');
    const payloadEncoded = Buffer.from(JSON.stringify(payload)).toString('base64').replace(/=+$/, '');
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

// Users endpoint
app.get('/api/users', authenticateUser, async (req, res) => {
  try {
    const { data, error } = await supabaseService
      .from('users')
      .select('id, name, email, role'); // Removed role-based restriction to show all users

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

    const tasksWithUsers = await Promise.all(data.map(async (task) => {
      if (task.created_by) {
        const { data: createdByUser } = await supabase
          .from('users')
          .select('id, name, email, role')
          .eq('id', task.created_by)
          .single();
        task.created_by = createdByUser || task.created_by;
      }
      if (task.assigned_to) {
        const { data: assignedToUser } = await supabase
          .from('users')
          .select('id, name, email, role')
          .eq('id', task.assigned_to)
          .single();
        task.assigned_to = assignedToUser || task.assigned_to;
      }
      return task;
    }));

    res.json(tasksWithUsers || []);
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
      .insert([{
        id: uuidv4(),
        title,
        description,
        due_date,
        priority,
        status,
        created_by,
        assigned_to,
      }])
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
      .update({
        title,
        description,
        due_date,
        priority,
        status,
        assigned_to,
      })
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
      .insert([{
        id: uuidv4(),
        task_id: taskId,
        file_url,
        file_name,
      }])
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
    // Verify receiver exists
    const { data: receiver, error: receiverError } = await supabaseService
      .from('users')
      .select('id')
      .eq('id', receiver_id)
      .maybeSingle();

    if (receiverError || !receiver) {
      return res.status(404).json({ error: 'Receiver not found' });
    }

    const { data, error } = await supabaseService
      .from('chat')
      .insert([{
        id: uuidv4(),
        sender_id,
        receiver_id,
        message,
        created_at: new Date().toISOString(),
        is_read: false,
      }])
      .select()
      .single();

    if (error) throw error;
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
    console.log(`Fetching chat for sender: ${sender_id}, receiver: ${receiver_id} at ${new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' })}`);
    const userId = req.user.id;
    if (sender_id !== userId && receiver_id !== userId) {
      return res.status(403).json({ error: 'Forbidden: You can only view your own conversations' });
    }

    const { data, error } = await supabaseService
      .from('chat')
      .select('*')
      .or(`sender_id.eq.${sender_id},receiver_id.eq.${sender_id}`)
      .or(`sender_id.eq.${receiver_id},receiver_id.eq.${receiver_id}`)
      .order('created_at', { ascending: true });

    if (error) throw error;

    console.log(`Chat data returned: ${JSON.stringify(data)}`);
    res.json(data || []);
  } catch (err) {
    console.error('Error fetching messages at', new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }), ':', err.message);
    res.status(500).json({ error: 'Failed to fetch messages' });
  }
});

app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});