VOTER_FILES_DB = YAML.load_file(File.join(Rails.root, 'config', 'voter_files_db.yml'))[Rails.env.to_s]
