import { useNavigate } from 'react-router-dom'
import FileUpload from '@/components/FileUpload/FileUpload'
import { useUpload } from '@/hooks/useUpload'
import './Upload.css'

function Upload() {
  const navigate = useNavigate()
  const { useUploadsList } = useUpload()
  const { data: uploads, refetch } = useUploadsList({ page: 1, page_size: 5 })

  // Navigate to dashboard after uploads
  const handleUploadsComplete = () => {
    refetch()
    // Optional: Navigate to dashboard after a delay
    setTimeout(() => {
      navigate('/dashboard')
    }, 2000)
  }

  return (
    <div className="upload-page">
      <div className="upload-header">
        <h1>Upload Media</h1>
        <p className="upload-description">
          Upload your photos and videos to make them searchable with AI
        </p>
      </div>

      {/* File Upload Component */}
      <FileUpload />

      {/* Recent Uploads Section */}
      {uploads && uploads.items.length > 0 && (
        <div className="recent-uploads">
          <h2>Recent Uploads</h2>
          <div className="recent-uploads-grid">
            {uploads.items.slice(0, 5).map((upload) => (
              <div key={upload.id} className="recent-upload-item">
                <div className="upload-thumbnail">
                  {upload.file_type === 'image' ? '🖼️' : '🎬'}
                </div>
                <div className="upload-info">
                  <p className="upload-filename">{upload.filename}</p>
                  <p className="upload-status">
                    <span className={`status-badge ${upload.processing_status}`}>
                      {upload.processing_status}
                    </span>
                  </p>
                </div>
              </div>
            ))}
          </div>
          <button 
            className="view-all-button" 
            onClick={() => navigate('/dashboard')}
          >
            View all uploads →
          </button>
        </div>
      )}

      {/* Tips Section */}
      <div className="upload-tips">
        <h3>💡 Tips for best results</h3>
        <ul>
          <li>Upload clear, high-quality images and videos</li>
          <li>Supported formats: JPEG, PNG, WebP, MP4, MOV</li>
          <li>Maximum file size: 100MB per file</li>
          <li>Our AI will analyze your media and make it searchable</li>
        </ul>
      </div>
    </div>
  )
}

export default Upload
