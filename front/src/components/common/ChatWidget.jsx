import React, { useState } from 'react';
import { Button } from 'react-bootstrap';
import Chat from '../landing/Chat'; // تأكد من المسار الصحيح

const ChatWidget = () => {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <>
      {/* الأيقونة العائمة */}
      <div
        style={{
          position: 'fixed',
          bottom: '20px',
          right: '20px',
          zIndex: 1050,
        }}
      >
        <Button
          onClick={() => setIsOpen(!isOpen)}
          style={{
            width: '60px',
            height: '60px',
            borderRadius: '50%',
            boxShadow: '0 4px 8px rgba(0,0,0,0.2)',
            background: '#3498db',
            border: 'none',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <i className="bi bi-chat-dots-fill" style={{ fontSize: '2rem', color: 'white' }}></i>
        </Button>
      </div>
          
      {/* نافذة الشات */}
      {isOpen && (
        <div
          style={{
            position: 'fixed',
            bottom: '90px',
            right: '20px',
            width: '380px',
            height: '500px',
            backgroundColor: 'white',
            borderRadius: '10px',
            boxShadow: '0 4px 20px rgba(0,0,0,0.2)',
            zIndex: 1050,
            overflow: 'hidden',
            display: 'flex',
            flexDirection: 'column',
          }}
        >
          {/* رأس النافذة */}
          <div
            style={{
              padding: '10px 15px',
              backgroundColor: '#3498db',
              color: 'white',
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
            }}
          >
            <span>Mongez Chatbot</span>
            <Button
              variant="link"
              style={{ color: 'white', padding: 0 }}
              onClick={() => setIsOpen(false)}
            >
              <i className="bi bi-x-lg"></i>
            </Button>
          </div>
          {/* محتوى الشات */}
          <div style={{ flex: 1, overflow: 'hidden' }}>
            <Chat embedded={true} />
          </div>
        </div>
      )}
    </>
  );
};

export default ChatWidget;