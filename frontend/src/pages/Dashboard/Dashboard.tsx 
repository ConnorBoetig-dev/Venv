import { useUpload } from '@/hooks/useUpload'
import './Dashboard.css'

function Dashboard() {
  const { useUploadsList } = useUpload()
  const { data: uploads, isLoading } = useUploadsList()

  return (
    <div className="dashboard-page">
      <h1>Dashboard</h1>
      <div className="stats">
        <div className="stat-card">
          <h3>Total Uploads</h3>
          <p>{uploads?.total || 0}</p>
        </div>
      </div>
      {isLoading && <p>Loading uploads...</p>}
    </div>
  )
}

export default Dashboard
