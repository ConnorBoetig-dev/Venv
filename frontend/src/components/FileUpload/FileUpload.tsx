import { useState, useRef, DragEvent, ChangeEvent } from 'react'
import { useUpload } from '@/hooks/useUpload'
import { ALLOWED_IMAGE_TYPES, ALLOWED_VIDEO_TYPES, MAX_FILE_SIZE } from '@/types'
import { 
  CloudArrowUpIcon,
  InboxArrowDownIcon,
  PhotoIcon,
  VideoCameraIcon,
  DocumentIcon,
  CheckCircleIcon,
  XCircleIcon,
  ClockIcon,
  ArrowUpIcon,
  XMarkIcon
} from '@heroicons/react/24/outline'

interface FileWithProgress {
  file: File
  id: string
  progress: number
  status: 'pending' | 'uploading' | 'success' | 'error'
  error?: string
}

function FileUpload() {
  const { uploadFile, uploadProgress, isUploading } = useUpload()
  const [isDragging, setIsDragging] = useState(false)
  const [files, setFiles] = useState<FileWithProgress[]>([])
  const fileInputRef = useRef<HTMLInputElement>(null)
  const dragCounter = useRef(0)

  // Validate file
  const validateFile = (file: File): { valid: boolean; error?: string } => {
    // Check file size
    if (file.size > MAX_FILE_SIZE) {
      return { 
        valid: false, 
        error: `File too large. Maximum size is ${Math.round(MAX_FILE_SIZE / 1024 / 1024)}MB` 
      }
    }

    // Check file type
    const allowedTypes = [...ALLOWED_IMAGE_TYPES, ...ALLOWED_VIDEO_TYPES]
    if (!allowedTypes.includes(file.type)) {
      return { 
        valid: false, 
        error: 'Invalid file type. Only images and videos are allowed.' 
      }
    }

    return { valid: true }
  }

  // Handle file selection
  const handleFiles = (newFiles: FileList | File[]) => {
    const fileArray = Array.from(newFiles)
    
    const processedFiles: FileWithProgress[] = fileArray.map(file => {
      const validation = validateFile(file)
      return {
        file,
        id: `${file.name}-${Date.now()}`,
        progress: 0,
        status: validation.valid ? 'pending' : 'error',
        error: validation.error
      }
    })

    setFiles(prev => [...prev, ...processedFiles])

    // Auto-upload valid files
    processedFiles
      .filter(f => f.status === 'pending')
      .forEach(fileWithProgress => {
        uploadSingleFile(fileWithProgress)
      })
  }

  // Upload a single file
  const uploadSingleFile = async (fileWithProgress: FileWithProgress) => {
    setFiles(prev => 
      prev.map(f => 
        f.id === fileWithProgress.id 
          ? { ...f, status: 'uploading' as const }
          : f
      )
    )

    try {
      await uploadFile.mutateAsync(fileWithProgress.file)
      
      setFiles(prev => 
        prev.map(f => 
          f.id === fileWithProgress.id 
            ? { ...f, status: 'success' as const, progress: 100 }
            : f
        )
      )
    } catch (error: any) {
      setFiles(prev => 
        prev.map(f => 
          f.id === fileWithProgress.id 
            ? { 
                ...f, 
                status: 'error' as const, 
                error: error.response?.data?.detail || 'Upload failed' 
              }
            : f
        )
      )
    }
  }

  // Drag handlers
  const handleDragEnter = (e: DragEvent) => {
    e.preventDefault()
    e.stopPropagation()
    dragCounter.current++
    
    if (e.dataTransfer.items && e.dataTransfer.items.length > 0) {
      setIsDragging(true)
    }
  }

  const handleDragLeave = (e: DragEvent) => {
    e.preventDefault()
    e.stopPropagation()
    dragCounter.current--
    
    if (dragCounter.current === 0) {
      setIsDragging(false)
    }
  }

  const handleDragOver = (e: DragEvent) => {
    e.preventDefault()
    e.stopPropagation()
  }

  const handleDrop = (e: DragEvent) => {
    e.preventDefault()
    e.stopPropagation()
    setIsDragging(false)
    dragCounter.current = 0

    if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
      handleFiles(e.dataTransfer.files)
    }
  }

  // File input change
  const handleFileInput = (e: ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      handleFiles(e.target.files)
    }
  }

  // Remove file from list
  const removeFile = (id: string) => {
    setFiles(prev => prev.filter(f => f.id !== id))
  }

  // Clear all completed uploads
  const clearCompleted = () => {
    setFiles(prev => prev.filter(f => f.status !== 'success'))
  }

  // Get file icon based on type
  const getFileIcon = (file: File) => {
    if (file.type.startsWith('image/')) return PhotoIcon
    if (file.type.startsWith('video/')) return VideoCameraIcon
    return DocumentIcon
  }

  // Format file size
  const formatFileSize = (bytes: number) => {
    if (bytes < 1024) return bytes + ' B'
    if (bytes < 1048576) return Math.round(bytes / 1024) + ' KB'
    return (bytes / 1048576).toFixed(1) + ' MB'
  }

  // Get status icon
  const getStatusIcon = (status: FileWithProgress['status']) => {
    switch (status) {
      case 'pending': return ClockIcon
      case 'uploading': return ArrowUpIcon
      case 'success': return CheckCircleIcon
      case 'error': return XCircleIcon
    }
  }

  // Count files by status
  const counts = {
    total: files.length,
    pending: files.filter(f => f.status === 'pending').length,
    uploading: files.filter(f => f.status === 'uploading').length,
    success: files.filter(f => f.status === 'success').length,
    error: files.filter(f => f.status === 'error').length,
  }

  return (
    <div className="file-upload space-y-6">
      {/* Premium Glass Drop Zone */}
      <div
        className={`drop-zone group cursor-pointer border-2 border-dashed rounded-2xl p-12 text-center transition-all duration-300 ${
          isDragging 
            ? 'border-white bg-black/20 scale-105 pgv-glow-on-hover' 
            : 'border-white/20 hover:border-white/40 hover:bg-white/5'
        } ${files.length > 0 ? 'mb-6' : ''}`}
        onDragEnter={handleDragEnter}
        onDragLeave={handleDragLeave}
        onDragOver={handleDragOver}
        onDrop={handleDrop}
        onClick={() => fileInputRef.current?.click()}
      >
        <input
          ref={fileInputRef}
          type="file"
          multiple
          accept={[...ALLOWED_IMAGE_TYPES, ...ALLOWED_VIDEO_TYPES].join(',')}
          onChange={handleFileInput}
          className="hidden"
        />
        
        <div className="drop-zone-content space-y-4">
          <div className={`drop-zone-icon transition-all duration-300 ${
            isDragging ? 'scale-110 animate-bounce' : 'group-hover:scale-110'
          }`}>
            {isDragging ? (
              <InboxArrowDownIcon className="w-16 h-16 mx-auto text-white" />
            ) : (
              <CloudArrowUpIcon className="w-16 h-16 mx-auto text-gray-400" />
            )}
          </div>
          <h3 className="drop-zone-title text-2xl font-semibold text-white">
            {isDragging ? 'Drop files here' : 'Drag & drop files here'}
          </h3>
          <p className="drop-zone-subtitle text-gray-300">
            or <span className="browse-link text-white font-medium hover:text-gray-300 transition-colors">browse</span> to choose files
          </p>
          <p className="drop-zone-hint text-sm text-gray-400">
            Supports images and videos up to 100MB
          </p>
        </div>
      </div>

      {/* Glass File List */}
      {files.length > 0 && (
        <div className="file-list pgv-glass p-6 rounded-2xl">
          <div className="file-list-header flex justify-between items-center mb-4">
            <h3 className="text-xl font-semibold text-white">Upload Queue ({counts.total})</h3>
            {counts.success > 0 && (
              <button 
                className="clear-button pgv-button-glass px-4 py-2 rounded-lg text-sm hover:scale-105 transition-all duration-200" 
                onClick={clearCompleted}
              >
                Clear completed
              </button>
            )}
          </div>

          {/* Glass Summary Pills */}
          {counts.total > 1 && (
            <div className="upload-summary flex flex-wrap gap-2 mb-4">
              {counts.pending > 0 && (
                <span className="px-3 py-1 rounded-full bg-yellow-500/20 text-yellow-300 text-sm flex items-center gap-1">
                  <ClockIcon className="w-4 h-4" />
                  {counts.pending} pending
                </span>
              )}
              {counts.uploading > 0 && (
                <span className="px-3 py-1 rounded-full bg-blue-500/20 text-blue-300 text-sm flex items-center gap-1">
                  <ArrowUpIcon className="w-4 h-4" />
                  {counts.uploading} uploading
                </span>
              )}
              {counts.success > 0 && (
                <span className="px-3 py-1 rounded-full bg-green-500/20 text-green-300 text-sm flex items-center gap-1">
                  <CheckCircleIcon className="w-4 h-4" />
                  {counts.success} completed
                </span>
              )}
              {counts.error > 0 && (
                <span className="px-3 py-1 rounded-full bg-red-500/20 text-red-300 text-sm flex items-center gap-1">
                  <XCircleIcon className="w-4 h-4" />
                  {counts.error} failed
                </span>
              )}
            </div>
          )}

          {/* Premium File Items */}
          <div className="file-items space-y-3">
            {files.map(fileItem => {
              // Get progress from uploadProgress hook if uploading
              const progress = fileItem.status === 'uploading' 
                ? uploadProgress[`temp-${Date.now()}`]?.percentage || 0
                : fileItem.progress

              return (
                <div key={fileItem.id} className={`file-item pgv-glass p-4 rounded-xl flex items-center gap-4 transition-all duration-300 hover:scale-[1.02] ${
                  fileItem.status === 'success' ? 'border border-green-500/30' :
                  fileItem.status === 'error' ? 'border border-red-500/30' :
                  fileItem.status === 'uploading' ? 'border border-blue-500/30' :
                  'border border-transparent'
                }`}>
                  <div className="file-icon">
                    {(() => {
                      const IconComponent = getFileIcon(fileItem.file)
                      return <IconComponent className="w-8 h-8 text-gray-400" />
                    })()}
                  </div>
                  
                  <div className="file-details flex-1 min-w-0">
                    <div className="file-name text-white font-medium truncate">
                      {fileItem.file.name}
                    </div>
                    <div className="file-meta flex items-center gap-2 text-sm text-gray-400">
                      <span className="file-size">
                        {formatFileSize(fileItem.file.size)}
                      </span>
                      {fileItem.error && (
                        <span className="file-error text-red-400">
                          • {fileItem.error}
                        </span>
                      )}
                    </div>
                    
                    {fileItem.status === 'uploading' && (
                      <div className="progress-bar w-full h-2 bg-white/10 rounded-full mt-2 overflow-hidden">
                        <div 
                          className="progress-fill h-full bg-gradient-to-r from-black to-gray-700 rounded-full transition-all duration-300" 
                          style={{ width: `${progress}%` }}
                        />
                      </div>
                    )}
                  </div>

                  <div className="file-status flex items-center gap-2">
                    <div className="status-icon">
                      {(() => {
                        const IconComponent = getStatusIcon(fileItem.status)
                        return <IconComponent className={`w-5 h-5 ${
                          fileItem.status === 'success' ? 'text-green-400' :
                          fileItem.status === 'error' ? 'text-red-400' :
                          fileItem.status === 'uploading' ? 'text-blue-400' :
                          'text-yellow-400'
                        }`} />
                      })()}
                    </div>
                    {fileItem.status !== 'uploading' && (
                      <button
                        className="remove-button w-8 h-8 rounded-full bg-red-500/20 text-red-400 hover:bg-red-500/30 hover:scale-110 transition-all duration-200 flex items-center justify-center"
                        onClick={(e) => {
                          e.stopPropagation()
                          removeFile(fileItem.id)
                        }}
                        aria-label="Remove file"
                      >
                        <XMarkIcon className="w-4 h-4" />
                      </button>
                    )}
                  </div>
                </div>
              )
            })}
          </div>
        </div>
      )}
    </div>
  )
}

export default FileUpload
