# THESE FUNCTIONS ARE NO LONGER USED

create_smtp_creds_key_with_password <- function (id, user = NULL, provider = NULL, host = NULL, port = NULL, 
          use_ssl = NULL, overwrite = FALSE,password = NULL) 
{
  if (is.null(user)) 
    user <- ""
  blastula:::validate_keyring_available(fn_name = "create_smtp_creds_key_with_password")
  if (!(inherits(id, "character") || inherits(id, "numeric") || 
        inherits(id, "integer"))) {
    stop("The provided `id` value must be a single character or numeric value.", 
         call. = TRUE)
  }
  if (length(id) != 1) {
    stop("Only a vector of length 1 should be used for the `id` value.", 
         call. = FALSE)
  }
  if (is.na(id) || id == "") {
    stop("The value for `id` should not be `NA` or an empty string.", 
         call. = FALSE)
  }
  if (is.character(id) && grepl("-", id)) {
    stop("Hyphens are not allowed as characters for an `id` value", 
         call. = FALSE)
  }
  creds_tbl <- blastula:::get_keyring_creds_table()
  existing_key <- id %in% creds_tbl$id
  if (existing_key && !overwrite) {
    stop("The specified `id` corresponds to a credential key already in the key-value store:\n", 
         "* Use a different `id` value with `create_smtp_creds_key()`, or\n", 
         "* If intentional, overwrite the existing key using the `overwrite = TRUE` option", 
         call. = FALSE)
  }
  if (existing_key && overwrite) {
    delete_credential_key(id = id)
  }
  credentials_list <- blastula:::create_credentials_list(provider = provider, 
                                              user = user, host = host, port = port, use_ssl = use_ssl,password = password)
  service_name <- paste0("blastula-v", blastula:::schema_version, 
                         "-", id)
  serialized <- blastula:::JSONify_credentials(credentials_list)
  keyring::key_set_with_value(service = service_name, username = user, 
                              password = serialized)
  message("The system key store has been updated with the \"", 
          service_name, "\" key with the `id` value \"", 
          id, "\".\n", "* Use the `view_credential_keys()` function to see all available keys\n", 
          "* You can use this key within `smtp_send()` with ", 
          "`credentials = creds_key(\"", id, "\")`")
}



create_smtp_creds_file_with_password <- function (file, user = NULL, provider = NULL, host = NULL, port = NULL, use_ssl = NULL, password = NULL) 
{
  if (is.null(user)) 
    user <- ""
  credentials_list <- blastula:::create_credentials_list(provider = provider, 
                                              user = user, host = host, port = port, use_ssl = use_ssl,password = password)
  serialized <- blastula:::JSONify_credentials(credentials_list)
  writeLines(serialized, file)
  Sys.chmod(file, mode = "0600")
  message("The SMTP credentials file (`", file, "`) has been generated")
}
