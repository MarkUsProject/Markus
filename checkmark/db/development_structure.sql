CREATE TABLE `assignment_files` (
  `id` int(11) NOT NULL auto_increment,
  `assignment_id` int(11) default NULL,
  `filename` varchar(255) NOT NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `fk_assignment_files_assignments` (`assignment_id`),
  CONSTRAINT `fk_assignment_files_assignments` FOREIGN KEY (`assignment_id`) REFERENCES `assignments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `assignments` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  `description` varchar(255) default NULL,
  `message` text,
  `due_date` datetime default NULL,
  `group_limit` int(11) default '1',
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `index_assignments_on_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=latin1;

CREATE TABLE `schema_migrations` (
  `version` varchar(255) NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `sessions` (
  `id` int(11) NOT NULL auto_increment,
  `session_id` varchar(255) NOT NULL,
  `data` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `index_sessions_on_session_id` (`session_id`),
  KEY `index_sessions_on_updated_at` (`updated_at`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;

CREATE TABLE `users` (
  `id` int(11) NOT NULL auto_increment,
  `user_name` varchar(255) NOT NULL,
  `user_number` varchar(255) NOT NULL,
  `last_name` varchar(255) default NULL,
  `first_name` varchar(255) default NULL,
  `role` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `index_users_on_user_number` (`user_number`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;

INSERT INTO schema_migrations (version) VALUES ('20080729160237');

INSERT INTO schema_migrations (version) VALUES ('20080729162213');

INSERT INTO schema_migrations (version) VALUES ('20080729162322');

INSERT INTO schema_migrations (version) VALUES ('20080806143028');