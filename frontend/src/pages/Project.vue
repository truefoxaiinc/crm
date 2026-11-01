<template>
  <LayoutHeader v-if="project.doc">
    <template #left-header>
      <Breadcrumbs :items="breadcrumbs" />
    </template>
    <template #right-header>
      <Button
        v-if="activeTab === 'tasks'"
        :label="__('New Task')"
        iconLeft="lucide-plus"
        @click="createTask"
      />
      <Button :label="__('Edit Project')" iconLeft="lucide-pencil" @click="editProject" />
    </template>
  </LayoutHeader>

  <div v-if="!project.doc" class="flex h-full items-center justify-center">
    <LoadingIndicator class="size-6" />
  </div>
  <div v-else class="flex h-full min-h-0 flex-col overflow-hidden">
    <div class="border-b border-outline-gray-1 px-5 py-4">
      <div class="flex flex-wrap items-center gap-3">
        <h1 class="text-2xl-semibold text-ink-gray-9">{{ project.doc.project_name }}</h1>
        <span class="rounded-full bg-surface-gray-2 px-2.5 py-1 text-xs-medium text-ink-gray-7">
          {{ __(project.doc.status || 'Planned') }}
        </span>
        <span class="rounded-full bg-surface-gray-1 px-2.5 py-1 text-xs-medium text-ink-gray-6">
          {{ __(project.doc.priority || 'Medium') }} {{ __('Priority') }}
        </span>
      </div>
      <div class="mt-4 max-w-2xl">
        <div class="mb-1.5 flex justify-between text-sm text-ink-gray-6">
          <span>{{ __('Progress') }}</span><span>{{ project.doc.progress || 0 }}%</span>
        </div>
        <div class="h-2 overflow-hidden rounded-full bg-surface-gray-2">
          <div class="h-full rounded-full bg-surface-blue-6" :style="{ width: `${Math.min(project.doc.progress || 0, 100)}%` }" />
        </div>
      </div>
    </div>

    <nav class="flex gap-5 border-b border-outline-gray-1 px-5" aria-label="Project sections">
      <button
        v-for="tab in tabs"
        :key="tab.value"
        class="border-b-2 py-3 text-sm-medium"
        :class="activeTab === tab.value ? 'border-outline-gray-8 text-ink-gray-9' : 'border-transparent text-ink-gray-5'"
        @click="activeTab = tab.value"
      >
        {{ __(tab.label) }}
        <span v-if="tab.value === 'tasks' && tasks.data" class="ml-1 text-ink-gray-5">{{ tasks.data.length }}</span>
      </button>
    </nav>

    <div v-if="activeTab === 'overview'" class="min-h-0 flex-1 overflow-y-auto p-5">
      <div class="grid max-w-4xl gap-6 md:grid-cols-2">
        <section class="rounded-lg border border-outline-gray-2 p-4">
          <h2 class="mb-4 text-base-semibold text-ink-gray-9">{{ __('Schedule & ownership') }}</h2>
          <dl class="grid grid-cols-[minmax(7rem,auto)_1fr] gap-x-4 gap-y-3 text-sm">
            <dt class="text-ink-gray-5">{{ __('Project Manager') }}</dt><dd class="text-ink-gray-8">{{ project.doc.project_manager || __('Unassigned') }}</dd>
            <dt class="text-ink-gray-5">{{ __('Start Date') }}</dt><dd class="text-ink-gray-8">{{ displayDate(project.doc.start_date) }}</dd>
            <dt class="text-ink-gray-5">{{ __('Expected End') }}</dt><dd class="text-ink-gray-8">{{ displayDate(project.doc.expected_end_date) }}</dd>
          </dl>
        </section>
        <section class="rounded-lg border border-outline-gray-2 p-4">
          <h2 class="mb-4 text-base-semibold text-ink-gray-9">{{ __('Related CRM records') }}</h2>
          <div class="flex flex-col gap-3 text-sm">
            <button v-for="link in relatedRecords" :key="link.label" class="flex items-center justify-between gap-3 text-left" :disabled="!project.doc[link.field]" @click="openRelated(link.route, project.doc[link.field])">
              <span class="text-ink-gray-5">{{ __(link.label) }}</span>
              <span class="truncate text-ink-blue-7">{{ project.doc[link.field] || __('Not linked') }}</span>
            </button>
          </div>
        </section>
        <section v-if="project.doc.description" class="rounded-lg border border-outline-gray-2 p-4 md:col-span-2">
          <h2 class="mb-3 text-base-semibold text-ink-gray-9">{{ __('Description') }}</h2>
          <!-- Rich text from the project's description is sanitized before rendering. -->
          <!-- eslint-disable vue/no-v-html -->
          <div class="prose-f text-sm text-ink-gray-7" v-html="sanitizeHTML(project.doc.description)" />
          <!-- eslint-enable vue/no-v-html -->
        </section>
      </div>
    </div>

    <div v-else-if="activeTab === 'tasks'" class="min-h-0 flex-1 overflow-y-auto p-5">
      <div v-if="tasks.loading" class="flex justify-center p-8"><LoadingIndicator class="size-6" /></div>
      <div v-else-if="!tasks.data?.length" class="rounded-lg border border-dashed border-outline-gray-2 p-10 text-center">
        <p class="text-base-medium text-ink-gray-7">{{ __('No tasks for this project yet') }}</p>
        <Button class="mt-3" :label="__('Create a task')" iconLeft="lucide-plus" @click="createTask" />
      </div>
      <div v-else class="max-w-4xl divide-y divide-outline-gray-1 rounded-lg border border-outline-gray-2">
        <button v-for="task in tasks.data" :key="task.name" class="flex w-full items-center justify-between gap-4 p-4 text-left hover:bg-surface-gray-1" @click="editTask(task.name)">
          <div class="min-w-0">
            <div class="truncate text-base-medium text-ink-gray-9">{{ task.title }}</div>
            <div class="mt-1 text-sm text-ink-gray-5">{{ task.priority || __('No priority') }}<span v-if="task.due_date"> · {{ displayDate(task.due_date) }}</span></div>
          </div>
          <span class="shrink-0 rounded-full bg-surface-gray-2 px-2.5 py-1 text-xs-medium text-ink-gray-7">{{ __(task.status || 'Backlog') }}</span>
        </button>
      </div>
    </div>

    <div v-else class="min-h-0 flex-1 overflow-y-auto p-5">
      <form class="mb-6 flex max-w-3xl flex-col items-end gap-2 rounded-lg border border-outline-gray-2 p-3" @submit.prevent="addComment">
        <textarea
          v-model="newComment"
          class="min-h-20 w-full resize-y rounded-md border border-outline-gray-2 bg-surface-white p-3 text-sm text-ink-gray-8 outline-none focus:border-outline-gray-4"
          :placeholder="__('Write a project update or comment…')"
          :aria-label="__('Project comment')"
        />
        <Button variant="solid" :label="__('Add Comment')" :disabled="!newComment.trim() || savingComment" :loading="savingComment" type="submit" />
      </form>
      <div v-if="timeline.loading" class="flex justify-center p-8"><LoadingIndicator class="size-6" /></div>
      <div v-else-if="!timelineEvents.length" class="p-8 text-center text-sm text-ink-gray-5">{{ __('Project activity will appear here.') }}</div>
      <ol v-else class="max-w-3xl">
        <li v-for="(event, index) in timelineEvents" :key="event.name || `${event.creation}-${index}`" class="relative grid grid-cols-[2rem_minmax(0,1fr)] gap-3 pb-6">
          <div class="relative flex justify-center">
            <span v-if="index < timelineEvents.length - 1" class="absolute bottom-0 top-7 w-px bg-outline-gray-2" />
            <span class="z-10 grid size-7 place-items-center rounded-full border border-outline-gray-2 bg-surface-white text-ink-gray-6">
              <Icon :icon="event.activity_type === 'comment' ? 'lucide-message-square' : event.activity_type === 'creation' ? 'lucide-circle-plus' : 'lucide-pencil'" class="size-3.5" />
            </span>
          </div>
          <div class="min-w-0 pt-1">
            <div class="text-sm text-ink-gray-8">
              <span class="font-medium">{{ ownerName(event.owner) }}</span>
              <span v-if="event.activity_type === 'creation'"> {{ event.data }}</span>
              <span v-else-if="event.activity_type === 'comment'"> {{ __('added a comment') }}</span>
              <span v-else> {{ __(event.activity_type) }} {{ event.data?.field_label }}</span>
            </div>
            <p v-if="event.activity_type === 'comment'" class="mt-2 whitespace-pre-wrap rounded-md bg-surface-gray-1 p-3 text-sm text-ink-gray-7">{{ event.content }}</p>
            <p v-else-if="event.data?.field_label" class="mt-1 text-sm text-ink-gray-6">
              {{ event.data.old_value || __('Empty') }} <span class="px-1">→</span> {{ event.data.value || __('Empty') }}
            </p>
            <time class="mt-1 block text-xs text-ink-gray-5">{{ displayDateTime(event.creation) }}</time>
          </div>
        </li>
      </ol>
    </div>
  </div>
</template>

<script setup>
import LayoutHeader from '@/components/LayoutHeader.vue'
import Icon from '@/components/Icon.vue'
import LoadingIndicator from '@/components/Icons/LoadingIndicator.vue'
import { useDocument } from '@/data/document'
import { useDoctypeModal } from '@/composables/doctypeModal'
import { usersStore } from '@/stores/users'
import { formatDate, sanitizeHTML } from '@/utils'
import { Breadcrumbs, call, createListResource, createResource, toast } from 'frappe-ui'
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'

const props = defineProps({ projectId: { type: String, required: true } })
const router = useRouter()
const { getUser } = usersStore()
const { showModal } = useDoctypeModal()
const { document: project } = useDocument('CRM Project', props.projectId)
const activeTab = ref('overview')
const newComment = ref('')
const savingComment = ref(false)

const tasks = createListResource({
  doctype: 'CRM Task',
  fields: ['name', 'title', 'status', 'priority', 'due_date', 'assigned_to'],
  filters: { project: props.projectId },
  orderBy: 'modified desc',
  pageLength: 100,
  auto: true,
})

const timeline = createResource({
  url: 'crm.api.activities.get_activities',
  params: { name: props.projectId },
  auto: true,
  transform: (result) => result?.[0] || [],
})

const tabs = [
  { label: 'Overview', value: 'overview' },
  { label: 'Tasks', value: 'tasks' },
  { label: 'Timeline', value: 'timeline' },
]

const breadcrumbs = computed(() => [
  { label: __('Projects'), route: { name: 'Projects' } },
  { label: project.doc?.project_name || props.projectId },
])

const relatedRecords = [
  { label: 'Lead', field: 'lead', route: 'Lead' },
  { label: 'Deal', field: 'deal', route: 'Deal' },
  { label: 'Contact', field: 'contact', route: 'Contact' },
  { label: 'Organization', field: 'organization', route: 'Organization' },
]

const timelineEvents = computed(() => timeline.data || [])

function editProject() {
  showModal({
    name: props.projectId,
    doctype: 'CRM Project',
    title: 'Project',
    callbacks: {
      afterUpdate: () => {
        project.reload()
        timeline.reload()
      },
    },
  })
}

function createTask() {
  showModal({
    doctype: 'CRM Task',
    title: 'Task',
    defaults: {
      project: props.projectId,
      reference_doctype: 'CRM Project',
      reference_docname: props.projectId,
      status: 'Backlog',
      priority: 'Medium',
    },
    callbacks: { afterInsert: () => tasks.reload(), afterUpdate: () => tasks.reload() },
  })
}

function editTask(name) {
  showModal({
    name,
    doctype: 'CRM Task',
    title: 'Task',
    callbacks: { afterUpdate: () => tasks.reload() },
  })
}

async function addComment() {
  const content = newComment.value.trim()
  if (!content || savingComment.value) return
  savingComment.value = true
  try {
    await call('crm.api.comment.add_comment', {
      reference_doctype: 'CRM Project',
      reference_name: props.projectId,
      content,
    })
    newComment.value = ''
    await timeline.reload()
    toast.success(__('Comment added'))
  } catch (error) {
    toast.error(error.messages?.[0] || __('Could not add comment'))
  } finally {
    savingComment.value = false
  }
}

function openRelated(route, name) {
  if (!name) return
  const params = {
    Lead: { leadId: name },
    Deal: { dealId: name },
    Contact: { contactId: name },
    Organization: { organizationId: name },
  }
  router.push({ name: route, params: params[route] })
}

function displayDate(value) {
  return value ? formatDate(value) : __('Not set')
}

function displayDateTime(value) {
  return value ? formatDate(value) : ''
}

function ownerName(user) {
  if (!user) return __('Someone')
  return getUser(user)?.full_name || (user === 'Administrator' ? user : user.split('@')[0])
}
</script>
