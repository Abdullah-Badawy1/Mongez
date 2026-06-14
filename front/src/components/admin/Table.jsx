import React from 'react';

const Table = ({ columns, data, loading, emptyMessage = 'No data found' }) => {
  if (loading) {
    return (
      <div className="text-center py-5">
        <div className="spinner-border" style={{ color: '#6366f1' }} role="status">
          <span className="visually-hidden">Loading...</span>
        </div>
      </div>
    );
  }

  if (!data || data.length === 0) {
    return (
      <div className="text-center py-5 text-muted">
        <i className="bi bi-inbox fs-1 d-block mb-2"></i>
        {emptyMessage}
      </div>
    );
  }

  return (
    <div className="table-responsive">
      <table className="table table-hover align-middle mb-0">
        <thead>
          <tr style={{ backgroundColor: '#f8fafc' }}>
            {columns.map((col) => (
              <th
                key={col.key}
                className="fw-semibold text-muted"
                style={{ fontSize: '13px', textTransform: 'uppercase', letterSpacing: '0.5px', borderBottom: '2px solid #e2e8f0' }}
              >
                {col.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {data.map((row, idx) => (
            <tr key={row.id || idx} style={{ borderBottom: '1px solid #f1f5f9' }}>
              {columns.map((col) => (
                <td key={col.key} style={{ fontSize: '14px', color: '#475569' }}>
                  {col.render ? col.render(row) : row[col.key]}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default Table;
