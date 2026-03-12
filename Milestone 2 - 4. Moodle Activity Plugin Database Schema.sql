CREATE TABLE `users` (
  `id` integer PRIMARY KEY,
  `username` varchar(255),
  `password` varchar(255)
);

CREATE TABLE `projects` (
  `id` integer PRIMARY KEY,
  `userid` integer,
  `project_type` enum,
  `project_name` varchar(255),
  `project_url` varchar(255),
  `created` timestamp
);

CREATE TABLE `labels` (
  `id` integer PRIMARY KEY,
  `p_id` integer,
  `label` varchar(255)
);

CREATE TABLE `examples` (
  `id` integer PRIMARY KEY,
  `p_id` integer,
  `example` varchar(255)
);

CREATE TABLE `training` (
  `id` integer PRIMARY KEY,
  `p_id` integer,
  `trained` timestamp
);

CREATE TABLE `predictions` (
  `id` integer PRIMARY KEY,
  `p_id` integer,
  `input` varchar(255),
  `output` varchar(255)
);

CREATE TABLE `scratch` (
  `id` integer PRIMARY KEY,
  `p_id` integer,
  `url` varchar(255)
);

CREATE TABLE `python` (
  `id` integer PRIMARY KEY,
  `p_id` integer,
  `instructions` varchar(255),
  `py_code` varchar(255)
);

CREATE TABLE `studentActivity` (
  `id` integer PRIMARY KEY,
  `activity_id` integer,
  `student_id` integer,
  `first_access` timestamp,
  `last_access` timestamp,
  `models_created` integer,
  `training_sessions` integer,
  `testing_sessions` integer
);

CREATE TABLE `studentModels` (
  `model_id` integer PRIMARY KEY,
  `student_id` integer,
  `name` Varchar,
  `model_type` enum,
  `created_at` Timestamp
);

ALTER TABLE `projects` ADD FOREIGN KEY (`userid`) REFERENCES `users` (`id`);

ALTER TABLE `labels` ADD FOREIGN KEY (`p_id`) REFERENCES `projects` (`id`);

ALTER TABLE `examples` ADD FOREIGN KEY (`p_id`) REFERENCES `projects` (`id`);

ALTER TABLE `training` ADD FOREIGN KEY (`p_id`) REFERENCES `projects` (`id`);

ALTER TABLE `predictions` ADD FOREIGN KEY (`p_id`) REFERENCES `projects` (`id`);

ALTER TABLE `scratch` ADD FOREIGN KEY (`p_id`) REFERENCES `projects` (`id`);

ALTER TABLE `python` ADD FOREIGN KEY (`p_id`) REFERENCES `projects` (`id`);

ALTER TABLE `studentActivity` ADD FOREIGN KEY (`activity_id`) REFERENCES `projects` (`id`);

ALTER TABLE `studentActivity` ADD FOREIGN KEY (`student_id`) REFERENCES `users` (`id`);

ALTER TABLE `studentModels` ADD FOREIGN KEY (`student_id`) REFERENCES `users` (`id`);
