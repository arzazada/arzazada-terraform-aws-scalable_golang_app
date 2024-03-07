{
  "agent": {
    "run_as_user": "cwagent"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "${appdir}/main.log",
            "log_group_class": "STANDARD",
            "log_group_name": "${project_name}",
            "log_stream_name": "{instance_id}",
            "retention_in_days": -1
          }
        ]
      }
    }
  }
}