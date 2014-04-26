@ssh_key = "PATH_TO_SSH_KEY_FOR_USER_RUNNING_TASKTRACKER_PROCESS_ON_REMOTE_HOST"
@ssh_user = "USERNAME_RESPONSIBLE_FOR_RUNNING_TASKTRACKER_ON_REMOTE_HOST"
#If hadoop-daemo.sh script is in PATH for @ssh_user, use the command below or else export PATH which contains the required script.
@command = "hadoop-daemon.sh stop tasktracker; sleep 5; hadoop-daemon.sh start tasktracker"
