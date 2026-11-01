<template>
  <LayoutHeader>
    <template #left-header>
      <ViewBreadcrumbs v-model="viewControls" routeName="Projects" />
    </template>
    <template #right-header>
      <CustomActions
        v-if="projectsListView?.customListActions"
        :actions="projectsListView.customListActions"
      />
      <Button
        variant="solid"
        :label="__('Create')"
        iconLeft="lucide-plus"
        @click="createProject"
      />
    </template>
  </LayoutHeader>

  <ViewControls
    ref="viewControls"
    v-model="projects"
    v-model:loadMore="loadMore"
    v-model:resizeColumn="triggerResize"
    v-model:updatedPageCount="updatedPageCount"
    doctype="CRM Project"
    :options="{ allowedViews: ['list'] }"
  />

  <ProjectsListView
    v-if="projects.data && rows.length"
    ref="projectsListView"
    v-model="projects.data.page_length_count"
    v-model:list="projects"
    :rows="rows"
    :columns="columns"
    :options="{
      resizeColumn: true,
      rowCount: projects.data.row_count,
      totalCount: projects.data.total_count,
    }"
    @loadMore="() => loadMore++"
    @columnWidthUpdated="() => triggerResize++"
    @updatePageCount="(count) => (updatedPageCount = count)"
  />

  <EmptyState
    v-else-if="projects.data && !rows.length"
    name="Projects"
    icon="lucide-briefcase-business"
    :title="__('No projects yet')"
    :description="__('Create a project to plan work and connect it to your CRM records.')"
    :filtered="!!Object.keys(projects.params?.filters || {}).length"
    @create="createProject"
  />

  <div v-else class="flex h-full items-center justify-center">
    <LoadingIndicator class="size-6" />
  </div>
</template>

<script setup>
import CustomActions from '@/components/CustomActions.vue'
import EmptyState from '@/components/ListViews/EmptyState.vue'
import LoadingIndicator from '@/components/Icons/LoadingIndicator.vue'
import LayoutHeader from '@/components/LayoutHeader.vue'
import ProjectsListView from '@/components/ListViews/ProjectsListView.vue'
import ViewBreadcrumbs from '@/components/ViewBreadcrumbs.vue'
import ViewControls from '@/components/ViewControls.vue'
import { useDoctypeModal } from '@/composables/doctypeModal'
import { getMeta } from '@/stores/meta'
import { usersStore } from '@/stores/users'
import { formatDate } from '@/utils'
import { computed, ref } from 'vue'

const { getUser } = usersStore()
const { getFormattedPercent } = getMeta('CRM Project')
const projectsListView = ref(null)
const projects = ref({})
const loadMore = ref(1)
const triggerResize = ref(1)
const updatedPageCount = ref(20)
const viewControls = ref(null)
const { showModal } = useDoctypeModal()

const rows = computed(() => {
  const data = projects.value?.data
  if (!data?.data || data.view_type !== 'list') return []

  return data.data.map((project) => {
    const row = { name: project.name }
    for (const field of data.rows || []) {
      const column = data.columns?.find((item) => item.key === field)
      const value = project[field]

      if (column?.type === 'Date' && value) {
        row[field] = formatDate(value, '', true)
      } else if (column?.type === 'Percent' && value != null) {
        row[field] = getFormattedPercent(field, project)
      } else if (field === 'project_manager' && value) {
        const user = getUser(value)
        row[field] = { label: user.full_name || value, name: value }
      } else {
        row[field] = value
      }
    }
    return row
  })
})

const columns = computed(() => projects.value?.data?.columns || [])

function createProject() {
  showModal({
    doctype: 'CRM Project',
    title: 'Project',
    defaults: { status: 'Planned', priority: 'Medium', progress: 0 },
    callbacks: {
      afterInsert: () => projects.value.reload(),
      afterUpdate: () => projects.value.reload(),
    },
  })
}
</script>
