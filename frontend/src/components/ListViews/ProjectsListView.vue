<template>
  <ListView
    :columns="columns"
    :rows="rows"
    :options="{
      getRowRoute: (row) => ({
        name: 'Project',
        params: { projectId: row.name },
      }),
      selectable: false,
      showTooltip: true,
      resizeColumn: options.resizeColumn,
    }"
    row-key="name"
  >
    <ListHeader
      class="mx-3 sm:mx-5"
      @columnWidthUpdated="emit('columnWidthUpdated')"
    >
      <ListHeaderItem
        v-for="column in columns"
        :key="column.key"
        :item="column"
        @columnWidthUpdated="(event) => onColumnWidthUpdated(event, column)"
      />
    </ListHeader>

    <ListRows v-slot="{ column, item }" class="mx-3 sm:mx-5" :rows="rows" doctype="CRM Project">
      <ListRowItem :item="item" :align="column.align" class="overflow-hidden">
        <template #default="{ label }">
          <div v-if="column.key === 'status' && label" class="truncate">
            <Badge
              variant="subtle"
              :theme="statusTheme(label)"
              size="md"
              :label="__(label)"
            />
          </div>
          <div v-else-if="column.key === 'priority' && label" class="truncate">
            <Badge
              variant="subtle"
              :theme="priorityTheme(label)"
              size="md"
              :label="__(label)"
            />
          </div>
          <div v-else-if="column.key === 'progress'" class="flex min-w-24 items-center gap-2">
            <div class="h-1.5 flex-1 overflow-hidden rounded-full bg-surface-gray-2">
              <div
                class="h-full rounded-full bg-surface-blue-6"
                :style="{ width: `${progressValue(label)}%` }"
              />
            </div>
            <span class="w-9 text-right text-sm text-ink-gray-6">{{ label || '0%' }}</span>
          </div>
          <div v-else class="truncate text-base" :title="label || ''">
            {{ label || '—' }}
          </div>
        </template>
      </ListRowItem>
    </ListRows>
  </ListView>

  <ListFooter
    v-model="pageLengthCount"
    class="border-t px-3 py-2 sm:px-5"
    :options="{
      rowCount: options.rowCount,
      totalCount: options.totalCount,
    }"
    @loadMore="emit('loadMore')"
  />
</template>

<script setup>
import ListRows from '@/components/ListViews/ListRows.vue'
import {
  ListView,
  ListHeader,
  ListHeaderItem,
  ListRowItem,
  ListFooter,
} from 'frappe-ui/experimental'
import { watch } from 'vue'

defineProps({
  rows: { type: Array, required: true },
  columns: { type: Array, required: true },
  options: {
    type: Object,
    default: () => ({ resizeColumn: false, totalCount: 0, rowCount: 0 }),
  },
})

const emit = defineEmits(['loadMore', 'updatePageCount', 'columnWidthUpdated'])
const pageLengthCount = defineModel({ type: Number })

function onColumnWidthUpdated({ width, save }, column) {
  column.width = width
  if (save) emit('columnWidthUpdated', column)
}

watch(pageLengthCount, (value, oldValue) => {
  if (value !== oldValue) emit('updatePageCount', value)
})

function progressValue(value) {
  const parsed = Number.parseFloat(String(value || 0).replace('%', ''))
  return Math.min(Math.max(Number.isFinite(parsed) ? parsed : 0, 0), 100)
}

function statusTheme(status) {
  return {
    Planned: 'gray',
    'In Progress': 'blue',
    'On Hold': 'orange',
    Completed: 'green',
    Cancelled: 'red',
  }[status] || 'gray'
}

function priorityTheme(priority) {
  return { Low: 'gray', Medium: 'blue', High: 'orange' }[priority] || 'gray'
}
</script>
