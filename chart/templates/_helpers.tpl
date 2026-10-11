{{- define "demo-service.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "demo-service.fullname" -}}
{{- printf "%s" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "demo-service.labels" -}}
app.kubernetes.io/name: {{ include "demo-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}
