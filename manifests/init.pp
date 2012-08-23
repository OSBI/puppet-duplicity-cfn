# Class: duplicity
#
# This module manages backups using duplicity
#
# Parameters:
#
#	$backup_action = ['backup' | 'restore' | 'none']
#	$file_dest = "S3 Address for backup files"
#	$access_id = "BackupAgent AWS Access Key Id"
#	$access_key = "BackupAgent AWS Secret Access Key"
#	$backup_filelist = '/etc
#						/home'
#
# Actions:
#   - Install the duplicity package
#
# Requires:
#
# Sample Usage:
#  class { 'duplicity': 
#    backup_filelist => '/etc
#						 /home'
#  }
#
class duplicity (
	$backup_action = $::cfn_backup_action,
	$file_dest = $::cfn_file_dest,
	$access_id = $::cfn_access_id,
	$secret_key = $::cfn_secret_key,
	$backup_filelist
) {
  
  package {['duplicity','python-boto']: 
    ensure 	=> latest,
  }
  
  if ($backup_action == 'backup' or $backup_action == 'restore') {
	
    if (!$file_dest) {
      fail('You need to define a file destination for backups!')
    }
    if (!$access_id or !$secret_key) {
      fail("You need to set all of your key variables: aws_access_key_id and aws_secret_access_key")
    }
	
	file { '/root/scripts' :
	  ensure	=> directory,
	  owner		=> root, group => 0, mode => 0500,
	}
	
	file { '/etc/duplicity' :
	  ensure	=> directory,
	  owner		=> root, group => 0, mode => 0500,
	}
	
	file { 'backup-filelist' :
	  path		=> '/etc/duplicity/backup-filelist.txt',
	  content	=> "$backup_filelist",
	  ensure	=> file,
	  mode		=> 644,
	  require	=> [File['/etc/duplicity'], Package['duplicity','python-boto']],
	}
	
	if ($backup_action == 'backup') {
	  
      file { "cloud-backup.sh":
        path 	=> '/root/scripts/cloud-backup.sh',
        content => template('duplicity/cloud-backup.sh.erb'),
        require => [File['/root/scripts'], Package['duplicity','python-boto']],
        owner 	=> root, group => 0, mode => 0700,
        ensure 	=> file,
      }
	  
      cron { 'duplicity_backup_cron':
        command => '/bin/sh /root/scripts/cloud-backup.sh',
	    ensure	=> present,
        user 	=> 'root',
        minute 	=> 0,
        hour 	=> 10,
        require => [ File['cloud-backup.sh'] ],
      }
	} else {
	  
      file { "cloud-restore.sh":
        path 	=> '/root/scripts/cloud-restore.sh',
        content => template('duplicity/cloud-restore.sh.erb'),
        require => [File['/root/scripts'], Package['duplicity','python-boto']],
        owner 	=> root, group => 0, mode => 0700,
        ensure 	=> file,
      }
	}
  } else {
	cron { 'duplicity_backup_cron':
      command 	=> '/bin/bash /root/scripts/cloud-backup.sh',
	  ensure	=> absent,
      user 		=> 'root',
      minute 	=> 0,
      hour 		=> 10,
	}
  }
}