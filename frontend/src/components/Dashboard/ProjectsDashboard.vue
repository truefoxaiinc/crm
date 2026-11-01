<template>
  <section class="mx-5 mb-6 rounded-lg border border-outline-gray-2 bg-surface-white">
    <div class="flex flex-wrap items-center justify-between gap-3 border-b border-outline-gray-1 px-4 py-3">
      <div>
        <h2 class="text-base-semibold text-ink-gray-9">{{ __('Projects') }}</h2>
        <p class="mt-0.5 text-sm text-ink-gray-5">{{ __('Progress, status, and project schedules') }}</p>
      </div>
      <Button
        variant="outline"
        size="sm"
        :label="__('View all')"
        iconRight="lucide-arrow-right"
        @click="router.push({ name: 'Projects' })"
      />
    </div>

    <div v-if="projects.loading" class="flex justify-center p-8">
      <LoadingIndicator class="size-5" />
    </div>
    <div v-else-if="!projectRows.length" class="px-4 py-8 text-center text-sm text-ink-gray-5">
      {{ __('No projects to show yet.') }}
    </div>
    <template v-else>
      <div class="grid grid-cols-1 divide-y divide-outline-gray-1 border-b border-outline-gray-1 sm:grid-cols-3 sm:divide-x sm:divide-y-0">
        <div v-for="stat in stats" :key="stat.label" class="px-4 py-3">
          <div class="text-sm text-ink-gray-5">{{ __(stat.label) }}</div>
          <div class="mt-1 text-xl-semibold text-ink-gray-9">{{ stat.value }}</div>
        </div>
      </div>

      <div class="overflow-x-auto">
        <div class="min-w-[760px]">
          <div class="grid grid-cols-[minmax(14rem,1.5fr)_8rem_11rem_minmax(17rem,2fr)] gap-4 border-b border-outline-gray-1 px-4 py-2 text-xs-medium uppercase tracking-wide text-ink-gray-5">
            <span>{{ __('Project') }}</span>
            <span>{{ __('Status') }}</span>
            <span>{{ __('Progress') }}</span>
            <div class="flex justify-between gap-2 normal-case tracking-normal">
              <span>{{ timelineStartLabel }}</span>
              <span>{{ __('Timeline') }}</span>
              <span>{{ timelineEndLabel }}</span>
            </div>
          </div>

          <button
            v-for="project in projectRows"
            :key="project.name"
            class="grid w-full grid-cols-[minmax(14rem,1.5fr)_8rem_11rem_minmax(17rem,2fr)] items-center gap-4 border-b border-outline-gray-1 px-4 py-3 text-left last:border-b-0 hover:bg-surface-gray-1"
            @click="router.push({ name: 'Project', params: { projectId: project.name } })"
          >
            <div class="min-w-0">
              <div class="truncate text-sm-medium text-ink-gray-9">{{ project.project_name }}</div>
              <div class="mt-0.5 truncate text-xs text-ink-gray-5">{{ project.name }}</div>
            </div>

            <div>
              <Badge
                variant="subtle"
                :theme="statusTheme(project.status)"
                size="md"
                :label="__(project.status || 'Planned')"
              />
            </div>

            <div class="flex items-center gap-2">
              <div class="h-1.5 flex-1 overflow-hidden rounded-full bg-surface-gray-2">
                <div
                  class="h-full rounded-full bg-surface-blue-6"
                  :style="{ width: `${progressValue(project.progress)}%` }"
                />
              </div>
              <span class="w-9 text-right text-xs-medium text-ink-gray-6">{{ progressValue(project.progress) }}%</span>
            </div>

            <div class="relative flex h-8 items-center">
              <div class="absolute inset-x-0 h-1.5 rounded-full bg-surface-gray-2" />
              <div
                class="absolute h-1.5 rounded-full"
                :class="project.status === 'Completed' ? 'bg-surface-green-6' : 'bg-surface-blue-6'"
                :style="timelineStyle(project)"
              />
              <div
                v-if="todayPosition !== null"
                class="absolute top-1 h-6 w-px bg-ink-gray-5"
                :style="{ left: `${todayPosition}%` }"
                :title="__('Today')"
              />
            </div>
          </button>
        </div>
      </div>
      <div class="flex items-center justify-end gap-2 px-4 py-2 text-xs text-ink-gray-5">
        <span class="size-2 rounded-full bg-surface-blue-6" />{{ __('Scheduled') }}
        <span class="ml-3 size-2 rounded-full bg-surface-green-6" />{{ __('Completed') }}
        <span class="ml-3 h-4 w-px bg-ink-gray-5" />{{ __('Today') }}
      </div>
    </template>
  </section>
</template>

<script setup lang="ts">
import LoadingIndicator from '@/components/Icons/LoadingIndicator.vue'
import { formatDate } from '@/utils'
import { createListResource } from 'frappe-ui'
import { computed } from 'vue'
import { useRouter } from 'vue-router'

type ProjectRow = {
  name: string
  project_name: string
  status: string
  progress: number
  start_date?: string
  expected_end_date?: string
}

const router = useRouter()
const projects = createListResource({
  doctype: 'CRM Project',
  fields: [
    'name',
    'project_name',
    'status',
    'progress',
    'start_date',
    'expected_end_date',
    'modified',
  ],
  orderBy: 'modified desc',
  pageLength: 100,
  auto: true,
})

const projectRows = computed<ProjectRow[]>(() => (projects.data || []).slice(0, 8))
const stats = computed(() => {
  const rows = projects.data || []
  return [
    { label: 'Total Projects', value: projects.data?.length || 0 },
    { label: 'In Progress', value: rows.filter((row) => row.status === 'In Progress').length },
    { label: 'Completed', value: rows.filter((row) => row.status === 'Completed').length },
  ]
})

const dayMs = 24 * 60 * 60 * 1000
const timelineBounds = computed(() => {
  const dates = projectRows.value.flatMap((project) =>
    [project.start_date, project.expected_end_date]
      .filter((date): date is string => Boolean(date))
      .map((date) => dateValue(date)),
  )
  const today = dateValue(new Date())
  if (!dates.length) return { start: today - 30 * dayMs, end: today + 30 * dayMs }
  const start = Math.min(...dates, today)
  const end = Math.max(...dates, today)
  return { start, end: end === start ? start + dayMs : end }
})

const timelineStartLabel = computed(() => formatDate(timelineBounds.value.start, 'MMM D'))
const timelineEndLabel = computed(() => formatDate(timelineBounds.value.end, 'MMM D'))
const todayPosition = computed(() => {
  const { start, end } = timelineBounds.value
  const today = dateValue(new Date())
  if (today < start || today > end) return null
  return ((today - start) / (end - start)) * 100
})

function dateValue(value: string | Date) {
  if (value instanceof Date) {
    return new Date(value.getFullYear(), value.getMonth(), value.getDate()).getTime()
  }
  const date = new Date(`${value}T00:00:00`)
  return Number.isNaN(date.getTime()) ? Date.now() : date.getTime()
}

function timelineStyle(project: ProjectRow) {
  const { start, end } = timelineBounds.value
  const projectStart = project.start_date ? dateValue(project.start_date) : start
  const projectEnd = project.expected_end_date
    ? dateValue(project.expected_end_date)
    : projectStart + 14 * dayMs
  const left = Math.max(0, Math.min(100, ((projectStart - start) / (end - start)) * 100))
  const right = Math.max(left + 2, Math.min(100, ((projectEnd - start) / (end - start)) * 100))
  return { left: `${left}%`, width: `${right - left}%` }
}

function progressValue(value?: number) {
  return Math.min(Math.max(Number(value) || 0, 0), 100)
}

function statusTheme(status?: string) {
  const themes: Record<string, string> = {
    Planned: 'gray',
    'In Progress': 'blue',
    'On Hold': 'orange',
    Completed: 'green',
    Cancelled: 'red',
  }
  return themes[status || 'Planned'] || 'gray'
}

defineExpose({ reload: () => projects.reload() })
</script>
