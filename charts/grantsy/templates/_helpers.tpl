{{/*
Expand the name of the chart.
*/}}
{{- define "grantsy.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Fully qualified app name.
*/}}
{{- define "grantsy.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Chart label value.
*/}}
{{- define "grantsy.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels.
*/}}
{{- define "grantsy.labels" -}}
helm.sh/chart: {{ include "grantsy.chart" . }}
{{ include "grantsy.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels.
*/}}
{{- define "grantsy.selectorLabels" -}}
app.kubernetes.io/name: {{ include "grantsy.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
ServiceAccount name.
*/}}
{{- define "grantsy.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "grantsy.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
True when the chart should provision SQLite-backed storage and enforce single-replica behavior.
Reads the operator's `config.database.driver`, defaulting to sqlite when unset.
*/}}
{{- define "grantsy.usesSqlite" -}}
{{- if eq (dig "database" "driver" "sqlite" .Values.config) "sqlite" -}}true{{- end -}}
{{- end -}}

{{/*
Name of the ConfigMap holding the rendered config.yaml.
*/}}
{{- define "grantsy.configMapName" -}}
{{- printf "%s-config" (include "grantsy.fullname" .) -}}
{{- end -}}

{{/*
Name of the PVC holding the SQLite database. Returns existingClaim when set.
*/}}
{{- define "grantsy.pvcName" -}}
{{- if .Values.persistence.existingClaim -}}
{{- .Values.persistence.existingClaim -}}
{{- else -}}
{{- include "grantsy.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Image reference. Falls back to .Chart.AppVersion when image.tag is empty.
*/}}
{{- define "grantsy.image" -}}
{{- $tag := default .Chart.AppVersion .Values.image.tag -}}
{{- printf "%s:%s" .Values.image.repository $tag -}}
{{- end -}}
