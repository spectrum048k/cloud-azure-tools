variable "resource_provider_names" {
  type  = list(string)
  default = [
  "Microsoft.PolicyInsights",
  "Microsoft.SecondProviderNamespace"
]
}