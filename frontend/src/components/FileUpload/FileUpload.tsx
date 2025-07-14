import { useState, useRef, DragEvent, ChangeEvent } from 'react'
import { useUpload } from '@/hooks/useUpload'
import { ALLOWED_IMAGE_TYPES, ALLOWED_VIDEO_TYPES, MAX_FILE_SIZE } from '@/types'
import './FileUpload.css'

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
    if (file.type.startsWith('image/')) return '🖼️'
    if (file.type.startsWith('video/')) return '🎬'
    return '📄'
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
      case 'pending': return '⏳'
      case 'uploading': return '📤'
      case 'success': return '✅'
      case 'error': return '❌'
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
    <div className="file-upload">
      {/* Drop Zone */}
      <div
        className={`drop-zone ${isDragging ? 'dragging' : ''} ${files.length > 0 ? 'has-files' : ''}`}
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
          className="file-input-hidden"
        />
        
        <div className="drop-zone-content">
          <div className="drop-zone-icon">
            {isDragging ? '📥' : '☁️'}
          </div>
          <h3 className="drop-zone-title">
            {isDragging ? 'Drop files here' : 'Drag & drop files here'}
          </h3>
          <p className="drop-zone-subtitle">
            or <span className="browse-link">browse</span> to choose files
          </p>
          <p className="drop-zone-hint">
            Supports images and videos up to 100MB
          </p>
        </div>
      </div>

      {/* File List */}
      {files.length > 0 && (
        <div className="file-list">
          <div className="file-list-header">
            <h3>Upload Queue ({counts.total})</h3>
            {counts.success > 0 && (
              <button 
                className="clear-button" 
                onClick={clearCompleted}
              >
                Clear completed
              </button>
            )}
          </div>

          {/* Summary */}
          {counts.total > 1 && (
            <div className="upload-summary">
              {counts.pending > 0 && <span>⏳ {counts.pending} pending</span>}
              {counts.uploading > 0 && <span>📤 {counts.uploading} uploading</span>}
              {counts.success > 0 && <span>✅ {counts.success} completed</span>}
              {counts.error > 0 && <span>❌ {counts.error} failed</span>}
            </div>
          )}

          {/* File Items */}
          <div className="file-items">
            {files.map(fileItem => {
              // Get progress from uploadProgress hook if uploading
              const progress = fileItem.status === 'uploading' 
                ? uploadProgress[`temp-${Date.now()}`]?.percentage || 0
                : fileItem.progress

              return (
                <div key={fileItem.id} className={`file-item ${fileItem.status}`}>
                  <div className="file-icon">
                    {getFileIcon(fileItem.file)}
                  </div>
                  
                  <div className="file-details">
                    <div className="file-name">
                      {fileItem.file.name}
                    </div>
                    <div className="file-meta">
                      <span className="file-size">
                        {formatFileSize(fileItem.file.size)}
                      </span>
                      {fileItem.error && (
                        <span className="file-error">
                          • {fileItem.error}
                        </span>
                      )}
                    </div>
                    
                    {fileItem.status === 'uploading' && (
                      <div className="progress-bar">
                        <div 
                          className="progress-fill" 
                          style={{ width: `${progress}%` }}
                        />
                      </div>
                    )}
                  </div>

                  <div className="file-status">
                    <span className="status-icon">
                      {getStatusIcon(fileItem.status)}
                    </span>
                    {fileItem.status !== 'uploading' && (
                      <button
                        className="remove-button"
                        onClick={(e) => {
                          e.stopPropagation()
                          removeFile(fileItem.id)
                        }}
                        aria-label="Remove file"
                      >
                        ×
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
