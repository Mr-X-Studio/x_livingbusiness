-- X Living Business | MR X | X Studio
-- The resource also creates these tables automatically on first start.

CREATE TABLE IF NOT EXISTS `x_businesses` (
  `id` VARCHAR(64) NOT NULL,
  `owner` VARCHAR(64) NOT NULL,
  `owner_name` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
  `funds` BIGINT NOT NULL DEFAULT 0,
  `level` INT NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `x_business_employees` (
  `business_id` VARCHAR(64) NOT NULL,
  `identifier` VARCHAR(64) NOT NULL,
  `name` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
  `wage` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`business_id`, `identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
