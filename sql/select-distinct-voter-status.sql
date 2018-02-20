select distinct jsonb_extract_path_text(voter_files, '1', 'status') as status from voters;
