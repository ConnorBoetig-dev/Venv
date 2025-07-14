import { useNavigate } from 'react-router-dom'
import FileUpload from '@/components/FileUpload/FileUpload'
import { useUpload } from '@/hooks/useUpload'
import { 
  PhotoIcon,
  VideoCameraIcon,
  FolderIcon,
  BoltIcon,
  CpuChipIcon,
  ArrowRightIcon
} from '@heroicons/react/24/outline'

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
    <div className="upload-page min-h-screen p-8 pgv-fade-in">
      {/* Hero Header with Glass Effect */}
      <div className="upload-header text-center mb-12">
        <h1 className="text-4xl font-bold mb-4 bg-gradient-to-r from-white to-gray-300 bg-clip-text text-transparent">
          Upload Media
        </h1>
        <p className="upload-description text-xl text-gray-300 max-w-2xl mx-auto leading-relaxed">
          Upload your photos and videos to make them searchable with AI vector semantic search
        </p>
      </div>

      {/* Main Upload Area */}
      <div className="max-w-4xl mx-auto space-y-8">
        {/* File Upload Component with Glass Container */}
        <div className="pgv-glass p-8 rounded-2xl pgv-liquid-hover">
          <FileUpload />
        </div>

        {/* Recent Uploads Section with Masonry Layout */}
        {uploads && uploads.items.length > 0 && (
          <div className="recent-uploads pgv-glass p-8 rounded-2xl">
            <h2 className="text-2xl font-display font-semibold mb-6 text-white tracking-tight">Recent Uploads</h2>
            <div className="recent-uploads-grid grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
              {uploads.items.slice(0, 5).map((upload) => (
                <div key={upload.id} className="recent-upload-item pgv-glass p-4 rounded-xl hover:scale-105 transition-all duration-300 pgv-glow-on-hover">
                  <div className="upload-thumbnail mb-3 text-center">
                    {upload.file_type === 'image' ? (
                      <PhotoIcon className="w-12 h-12 mx-auto text-gray-400" />
                    ) : (
                      <VideoCameraIcon className="w-12 h-12 mx-auto text-gray-400" />
                    )}
                  </div>
                  <div className="upload-info text-center">
                    <p className="upload-filename text-white font-medium mb-2 truncate">
                      {upload.filename}
                    </p>
                    <p className="upload-status">
                      <span className={`status-badge px-3 py-1 rounded-full text-xs font-medium ${
                        upload.processing_status === 'completed' ? 'bg-green-500/20 text-green-300' :
                        upload.processing_status === 'failed' ? 'bg-red-500/20 text-red-300' :
                        upload.processing_status === 'pending' ? 'bg-yellow-500/20 text-yellow-300' :
                        'bg-blue-500/20 text-blue-300'
                      }`}>
                        {upload.processing_status}
                      </span>
                    </p>
                  </div>
                </div>
              ))}
            </div>
            <button 
              className="view-all-button pgv-button pgv-button-primary w-full py-3 rounded-lg font-medium hover:scale-105 transition-all duration-300 flex items-center justify-center gap-2" 
              onClick={() => navigate('/dashboard')}
            >
              View all uploads
              <ArrowRightIcon className="w-4 h-4" />
            </button>
          </div>
        )}

        {/* Tips Section with Glass Cards */}
        <div className="upload-tips pgv-glass p-8 rounded-2xl">
          <h3 className="text-2xl font-display font-semibold mb-6 text-white flex items-center gap-3 tracking-tight">
            <BoltIcon className="w-8 h-8 text-yellow-400" />
            Tips for best results
          </h3>
          <div className="grid md:grid-cols-2 gap-4">
            {[
              { icon: PhotoIcon, text: 'Upload clear, high-quality images and videos', color: 'text-blue-400' },
              { icon: FolderIcon, text: 'Supported formats: JPEG, PNG, WebP, MP4, MOV', color: 'text-green-400' },
              { icon: BoltIcon, text: 'Maximum file size: 100MB per file', color: 'text-yellow-400' },
              { icon: CpuChipIcon, text: 'Our AI will analyze your media and make it searchable', color: 'text-purple-400' }
            ].map((tip, index) => (
              <div key={index} className="flex items-start gap-4 p-4 rounded-lg hover:bg-white/5 transition-colors duration-200">
                <tip.icon className={`w-6 h-6 ${tip.color} flex-shrink-0 mt-0.5`} />
                <span className="text-gray-300">{tip.text}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

export default Upload
