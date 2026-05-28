include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}//${get_path_from_repo_root()}"
}
