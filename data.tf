data "azurerm_key_vault" "key_vault" {
  name                = "prkvn"
  resource_group_name = "pr-infra"
}

data "azurerm_key_vault_secret" "tstateaccess {
  name         = "tstateaccess"
  key_vault_id = data.azurerm_key_vault.key_vault.id
}
