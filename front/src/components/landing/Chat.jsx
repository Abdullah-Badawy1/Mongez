import React, { useState, useRef, useEffect } from 'react';
import axios from 'axios';

const Chat = ({ embedded = false, onClose }) => {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [darkMode, setDarkMode] = useState(false);
  const messagesEndRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const toggleDarkMode = () => {
    setDarkMode(prev => !prev);
  };

  const clearChat = () => {
    setMessages([]);
  };

  const sendMessage = async () => {
    if (!input.trim() || loading) return;

    const userMessage = { role: 'user', content: input };
    const updatedMessages = [...messages, userMessage];
    setMessages(updatedMessages);
    setInput('');
    setLoading(true);

    try {
      const response = await axios.post(
        'https://openrouter.ai/api/v1/chat/completions',
        {
          model: 'openai/gpt-3.5-turbo',
          messages: updatedMessages.map(({ role, content }) => ({ role, content })),
        },
        {
          headers: {
            Authorization: `Bearer ${import.meta.env.VITE_OPENROUTER_KEY}`,
            'Content-Type': 'application/json',
            'HTTP-Referer': 'http://localhost:5173',
            'X-Title': 'Mongez Chatbot'
          },
        }
      );

      const assistantMessage = {
        role: 'assistant',
        content: response.data.choices[0].message.content,
      };
      setMessages(prev => [...prev, assistantMessage]);
    } catch (error) {
      console.error('API Error:', error);
      setMessages(prev => [
        ...prev,
        { role: 'assistant', content: 'Sorry, something went wrong. Please try again.' },
      ]);
    } finally {
      setLoading(false);
    }
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  const containerStyle = embedded
    ? { height: '100%', display: 'flex', flexDirection: 'column' }
    : { height: '100vh', display: 'flex', flexDirection: 'column' };

  const bgClass = darkMode ? 'bg-dark text-white' : 'bg-light';

  return (
    <div className={`${bgClass}`} style={containerStyle}>
      {!embedded && (
        <nav className={`navbar navbar-expand ${darkMode ? 'navbar-dark bg-dark' : 'navbar-light bg-light'} border-bottom`}>
          <div className="container-fluid">
            <span className="navbar-brand mb-0 h1">Mongez Chatbot</span>
            <div className="d-flex">
              <button className="btn btn-outline-secondary me-2" onClick={toggleDarkMode}>
                {darkMode ? '☀️' : '🌙'}
              </button>
              <button className="btn btn-outline-danger" onClick={clearChat}>
                Clear
              </button>
            </div>
          </div>
        </nav>
      )}

      <div className="flex-grow-1 overflow-auto p-3">
        <div className="container-xxl">
          {messages.map((msg, index) => (
            <div
              key={index}
              className={`d-flex ${msg.role === 'user' ? 'justify-content-end' : 'justify-content-start'} mb-3`}
            >
              <div
                className={`p-3 rounded-3 shadow-sm ${
                  msg.role === 'user'
                    ? 'bg-primary text-white'
                    : darkMode
                    ? 'bg-secondary text-white'
                    : 'bg-light text-dark'
                }`}
                style={{ maxWidth: '70%', wordWrap: 'break-word' }}
              >
                {msg.content}
              </div>
            </div>
          ))}
          {loading && (
            <div className="d-flex justify-content-start mb-3">
              <div className={`p-3 rounded-3 shadow-sm ${darkMode ? 'bg-secondary text-white' : 'bg-light'}`}>
                <div className="spinner-border spinner-border-sm me-2" role="status">
                  <span className="visually-hidden">Loading...</span>
                </div>
                Thinking...
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>
      </div>

      <div className={`p-3 ${darkMode ? 'bg-dark border-top border-secondary' : 'bg-light border-top'}`}>
        <div className="container-xxl">
          <div className="input-group">
            <input
              type="text"
              className={`form-control ${darkMode ? 'bg-dark text-white border-secondary' : ''}`}
              placeholder="Type your message..."
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={handleKeyDown}
              disabled={loading}
            />
            <button
              className="btn btn-primary"
              onClick={sendMessage}
              disabled={loading || !input.trim()}
            >
              Send
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Chat;