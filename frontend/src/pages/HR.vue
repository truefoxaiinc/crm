<template>
  <LayoutHeader>
    <template #left-header>
      <div class="flex items-center gap-2">
        <span class="grid size-8 place-items-center rounded-lg bg-surface-gray-2 text-ink-gray-7">
          <UsersRoundIcon class="size-4" />
        </span>
        <div>
          <div class="text-lg font-semibold leading-tight text-ink-gray-9">{{ __('People') }}</div>
          <div class="text-xs text-ink-gray-5">{{ __('Human resources workspace') }}</div>
        </div>
      </div>
    </template>
    <template #right-header>
      <Button variant="outline" :label="__('Open full HRMS')" iconLeft="lucide-external-link" @click="openHRMS" />
      <Button v-if="activeTab === 'Employees' && canCreateEmployees" variant="solid" :label="__('Add Employee')" iconLeft="lucide-plus" @click="openEmployee()" />
    </template>
  </LayoutHeader>

  <div class="flex h-full min-h-0 flex-col overflow-y-auto bg-surface-gray-1/40">
    <div class="border-b border-outline-gray-1 bg-surface-white px-4 sm:px-6">
      <nav class="flex gap-6 overflow-x-auto" aria-label="HR sections">
        <button
          v-for="tab in tabs"
          :key="tab"
          class="relative shrink-0 py-3 text-sm transition-colors"
          :class="activeTab === tab ? 'font-medium text-ink-gray-9' : 'text-ink-gray-5 hover:text-ink-gray-8'"
          @click="activeTab = tab"
        >
          {{ __(tab) }}
          <span v-if="activeTab === tab" class="absolute inset-x-0 bottom-0 h-0.5 rounded-full bg-ink-gray-9" />
        </button>
      </nav>
    </div>

    <main class="mx-auto w-full max-w-[1500px] p-4 sm:p-6">
      <template v-if="activeTab === 'Overview'">
        <div class="mb-5 flex flex-wrap items-end justify-between gap-3">
          <div>
            <h1 class="text-xl-semibold text-ink-gray-9">{{ __('People overview') }}</h1>
            <p class="mt-1 text-sm text-ink-gray-5">{{ __('A quick view of your team and HR activity') }}</p>
          </div>
          <Button variant="outline" :label="__('Manage HR settings')" iconLeft="lucide-settings-2" @click="openHRMS" />
        </div>

        <div class="mb-5 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
          <div v-for="card in summaryCards" :key="card.label" class="rounded-xl border border-outline-gray-2 bg-surface-white p-4 shadow-sm shadow-black/[0.02]">
            <div class="flex items-start justify-between">
              <span class="text-sm text-ink-gray-5">{{ __(card.label) }}</span>
              <span class="grid size-8 place-items-center rounded-lg bg-surface-gray-2 text-ink-gray-7"><Icon :icon="card.icon" class="size-4" /></span>
            </div>
            <div class="mt-3 flex items-baseline gap-2">
              <span class="text-2xl-semibold text-ink-gray-9">{{ card.value }}</span>
              <span class="text-xs text-ink-gray-5">{{ __(card.hint) }}</span>
            </div>
          </div>
        </div>

        <div class="grid gap-4 xl:grid-cols-3">
          <section class="overflow-hidden rounded-xl border border-outline-gray-2 bg-surface-white xl:col-span-2">
            <div class="flex items-center justify-between border-b border-outline-gray-1 px-4 py-3.5">
              <div>
                <h2 class="text-base font-semibold text-ink-gray-9">{{ __('Team members') }}</h2>
                <p class="mt-0.5 text-xs text-ink-gray-5">{{ __('Recently updated employee records') }}</p>
              </div>
              <Button variant="ghost" :label="__('View all')" @click="activeTab = 'Employees'" />
            </div>
            <div v-if="employeePermissions.loading || (canReadEmployees && employees.loading)" class="flex h-48 items-center justify-center"><LoadingIndicator class="size-6" /></div>
            <div v-else-if="!canReadEmployees" class="flex min-h-48 flex-col items-center justify-center px-5 text-center">
              <span class="mb-3 grid size-11 place-items-center rounded-full bg-surface-gray-1 text-ink-gray-6"><Icon icon="lucide-lock-keyhole" class="size-5" /></span>
              <div class="font-medium text-ink-gray-9">{{ __('Employee directory access required') }}</div>
              <p class="mt-1 max-w-md text-sm text-ink-gray-5">{{ __('Ask your administrator to grant Employee read access. Your CRM role does not automatically grant access to private HR records.') }}</p>
            </div>
            <div v-else-if="!employees.data?.length" class="flex min-h-48 flex-col items-center justify-center px-5 text-center">
              <span class="mb-3 grid size-11 place-items-center rounded-full bg-surface-gray-2 text-ink-gray-6"><UsersRoundIcon class="size-5" /></span>
              <div class="font-medium text-ink-gray-9">{{ __('Your team will appear here') }}</div>
              <p class="mt-1 max-w-md text-sm text-ink-gray-5">{{ __('Add an employee to start building your team directory.') }}</p>
              <Button v-if="canCreateEmployees" class="mt-3" variant="solid" :label="__('Add Employee')" iconLeft="lucide-plus" @click="openEmployee()" />
            </div>
            <div v-else class="overflow-x-auto">
              <table class="w-full min-w-[650px] text-left">
                <thead><tr class="border-b border-outline-gray-1 bg-surface-gray-1/70 text-xs-medium uppercase tracking-wide text-ink-gray-5"><th class="px-4 py-3">{{ __('Employee') }}</th><th class="px-4 py-3">{{ __('Department') }}</th><th class="px-4 py-3">{{ __('Designation') }}</th><th class="px-4 py-3">{{ __('Status') }}</th></tr></thead>
                <tbody>
                  <tr v-for="employee in employees.data.slice(0, 5)" :key="employee.name" class="border-b border-outline-gray-1 last:border-0 hover:bg-surface-gray-1/60" :class="canWriteEmployees && 'cursor-pointer'" @click="canWriteEmployees && openEmployee(employee.name)">
                    <td class="px-4 py-3"><div class="flex items-center gap-3"><span class="grid size-9 shrink-0 place-items-center rounded-full bg-surface-gray-2 text-sm font-medium text-ink-gray-7">{{ initials(employee.employee_name) }}</span><span><span class="block text-sm font-medium text-ink-gray-9">{{ employee.employee_name || employee.name }}</span><span class="mt-0.5 block text-xs text-ink-gray-5">{{ employee.company_email || employee.name }}</span></span></div></td>
                    <td class="px-4 py-3 text-sm text-ink-gray-7">{{ employee.department || '—' }}</td>
                    <td class="px-4 py-3 text-sm text-ink-gray-7">{{ employee.designation || '—' }}</td>
                    <td class="px-4 py-3"><Badge :label="__(employee.status || 'Active')" variant="subtle" :theme="employee.status === 'Active' ? 'green' : 'gray'" size="md" /></td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>

          <section class="rounded-xl border border-outline-gray-2 bg-surface-white p-4">
            <div class="mb-4 flex items-center justify-between"><div><h2 class="text-base font-semibold text-ink-gray-9">{{ __('Quick access') }}</h2><p class="mt-0.5 text-xs text-ink-gray-5">{{ __('Common people operations') }}</p></div><Icon icon="lucide-command" class="size-4 text-ink-gray-5" /></div>
            <div class="flex flex-col gap-2">
              <button v-for="item in quickLinks" :key="item.label" class="group flex items-center gap-3 rounded-lg border border-outline-gray-1 p-3 text-left transition-colors hover:bg-surface-gray-1" @click="openHRMS(item.path)">
                <span class="grid size-9 place-items-center rounded-lg bg-surface-gray-2 text-ink-gray-7 group-hover:bg-surface-gray-3"><Icon :icon="item.icon" class="size-4" /></span>
                <span class="min-w-0 flex-1"><span class="block text-sm font-medium text-ink-gray-9">{{ __(item.label) }}</span><span class="mt-0.5 block text-xs text-ink-gray-5">{{ __(item.hint) }}</span></span>
                <Icon icon="lucide-chevron-right" class="size-4 text-ink-gray-5" />
              </button>
            </div>
            <div class="mt-4 rounded-lg bg-surface-gray-1 p-3"><div class="flex gap-2"><Icon icon="lucide-info" class="mt-0.5 size-4 shrink-0 text-ink-gray-5" /><p class="text-xs leading-relaxed text-ink-gray-6">{{ __('Attendance, leave approvals, and India payroll processing are handled by the full HRMS module.') }}</p></div></div>
          </section>
        </div>
      </template>

      <template v-else-if="activeTab === 'Employees'">
        <div class="mb-5 flex flex-wrap items-end justify-between gap-3"><div><h1 class="text-xl-semibold text-ink-gray-9">{{ __('Employees') }}</h1><p class="mt-1 text-sm text-ink-gray-5">{{ __('Browse and manage your employee directory') }}</p></div><div v-if="canReadEmployees" class="flex items-center gap-2"><input v-model="search" class="h-9 w-60 rounded-md border border-outline-gray-2 bg-surface-white px-3 text-sm outline-none focus:border-outline-gray-4" :placeholder="__('Search employees')" /><Button v-if="canCreateEmployees" variant="solid" :label="__('Add Employee')" iconLeft="lucide-plus" @click="openEmployee()" /></div></div>
        <div v-if="employeePermissions.loading || (canReadEmployees && employees.loading)" class="flex h-48 items-center justify-center"><LoadingIndicator class="size-6" /></div>
        <div v-else-if="!canReadEmployees" class="rounded-xl border border-outline-gray-2 bg-surface-white px-5 py-14 text-center"><span class="mx-auto mb-3 grid size-11 place-items-center rounded-full bg-surface-gray-1 text-ink-gray-6"><Icon icon="lucide-lock-keyhole" class="size-5" /></span><div class="font-medium text-ink-gray-9">{{ __('Employee directory access required') }}</div><p class="mx-auto mt-1 max-w-lg text-sm text-ink-gray-5">{{ __('Ask your administrator to grant Employee read access. HR records are protected by Frappe permissions.') }}</p></div>
        <div v-else-if="!filteredEmployees.length" class="rounded-xl border border-outline-gray-2 bg-surface-white px-5 py-14 text-center"><span class="mx-auto mb-3 grid size-11 place-items-center rounded-full bg-surface-gray-2 text-ink-gray-6"><UsersRoundIcon class="size-5" /></span><div class="font-medium text-ink-gray-9">{{ search ? __('No matching employees') : __('No employees yet') }}</div><p class="mt-1 text-sm text-ink-gray-5">{{ __('Add your first employee to build your team directory.') }}</p><Button v-if="canCreateEmployees" class="mt-4" variant="solid" :label="__('Add Employee')" @click="openEmployee()" /></div>
        <div v-else class="overflow-x-auto rounded-xl border border-outline-gray-2 bg-surface-white"><table class="w-full min-w-[850px] text-left"><thead><tr class="border-b border-outline-gray-1 bg-surface-gray-1/70 text-xs-medium uppercase tracking-wide text-ink-gray-5"><th class="px-4 py-3">{{ __('Employee') }}</th><th class="px-4 py-3">{{ __('Department') }}</th><th class="px-4 py-3">{{ __('Designation') }}</th><th class="px-4 py-3">{{ __('Email') }}</th><th class="px-4 py-3">{{ __('Joining Date') }}</th><th class="px-4 py-3">{{ __('Status') }}</th></tr></thead><tbody><tr v-for="employee in filteredEmployees" :key="employee.name" class="border-b border-outline-gray-1 last:border-0 hover:bg-surface-gray-1/60" :class="canWriteEmployees && 'cursor-pointer'" @click="canWriteEmployees && openEmployee(employee.name)"><td class="px-4 py-3"><div class="flex items-center gap-3"><span class="grid size-9 place-items-center rounded-full bg-surface-gray-2 text-sm font-medium text-ink-gray-7">{{ initials(employee.employee_name) }}</span><span><span class="block text-sm font-medium text-ink-gray-9">{{ employee.employee_name || employee.name }}</span><span class="block text-xs text-ink-gray-5">{{ employee.name }}</span></span></div></td><td class="px-4 py-3 text-sm text-ink-gray-7">{{ employee.department || '—' }}</td><td class="px-4 py-3 text-sm text-ink-gray-7">{{ employee.designation || '—' }}</td><td class="px-4 py-3 text-sm text-ink-gray-7">{{ employee.company_email || employee.personal_email || '—' }}</td><td class="px-4 py-3 text-sm text-ink-gray-7">{{ formatDate(employee.date_of_joining) }}</td><td class="px-4 py-3"><Badge :label="__(employee.status || 'Active')" variant="subtle" :theme="employee.status === 'Active' ? 'green' : 'gray'" size="md" /></td></tr></tbody></table></div>
      </template>

      <template v-else>
        <div class="mb-5"><h1 class="text-xl-semibold text-ink-gray-9">{{ __(activeTab) }}</h1><p class="mt-1 text-sm text-ink-gray-5">{{ sectionDescription }}</p></div>
        <section class="rounded-xl border border-outline-gray-2 bg-surface-white px-5 py-14 text-center"><span class="mx-auto mb-3 grid size-11 place-items-center rounded-full bg-surface-gray-2 text-ink-gray-6"><Icon :icon="activeTab === 'Attendance' ? 'lucide-calendar-check' : activeTab === 'Leave' ? 'lucide-calendar-days' : 'lucide-wallet'" class="size-5" /></span><div class="font-medium text-ink-gray-9">{{ __(activeTab + ' is managed in HRMS') }}</div><p class="mx-auto mt-1 max-w-lg text-sm text-ink-gray-5">{{ __('Use the full HRMS workspace to review records, approvals, and India payroll. Your team and employee directory remain available here in CRM.') }}</p><Button class="mt-4" variant="solid" :label="__('Open ' + activeTab)" iconLeft="lucide-external-link" @click="openHRMS(sectionPaths[activeTab])" /></section>
      </template>
    </main>
  </div>
</template>

<script setup>
import LayoutHeader from '@/components/LayoutHeader.vue'
import LoadingIndicator from '@/components/Icons/LoadingIndicator.vue'
import UsersRoundIcon from '~icons/lucide/users-round'
import { useDoctypeModal } from '@/composables/doctypeModal'
import { createListResource, createResource } from 'frappe-ui'
import { computed, ref, watch } from 'vue'

const tabs = ['Overview', 'Employees', 'Attendance', 'Leave', 'Payroll']
const activeTab = ref('Overview')
const search = ref('')
const { showModal } = useDoctypeModal()
const employeePermissions = createResource({
  url: 'crm.api.session.get_doctype_permissions',
  params: { doctype: 'Employee' },
  auto: true,
})
const canReadEmployees = computed(() => !!employeePermissions.data?.read)
const canCreateEmployees = computed(() => !!employeePermissions.data?.create)
const canWriteEmployees = computed(() => !!employeePermissions.data?.write)
const employees = createListResource({
  doctype: 'Employee',
  fields: ['name', 'employee_name', 'department', 'designation', 'company_email', 'personal_email', 'status', 'date_of_joining', 'modified'],
  orderBy: 'modified desc',
  pageLength: 100,
  auto: false,
})
watch(canReadEmployees, (canRead) => {
  if (canRead && !employees.data && !employees.loading) employees.fetch()
}, { immediate: true })
const quickLinks = [
  { label: 'Attendance', hint: 'Daily presence and check-ins', icon: 'lucide-calendar-check', path: '/app/attendance' },
  { label: 'Leave requests', hint: 'Leave applications and approvals', icon: 'lucide-calendar-days', path: '/app/leave-application' },
  { label: 'Payroll', hint: 'Salary slips and payroll runs', icon: 'lucide-wallet', path: '/app/salary-slip' },
]
const sectionPaths = { Attendance: '/app/attendance', Leave: '/app/leave-application', Payroll: '/app/salary-slip' }
const filteredEmployees = computed(() => {
  const query = search.value.trim().toLowerCase()
  const data = employees.data || []
  if (!query) return data
  return data.filter((employee) =>
    [employee.employee_name, employee.name, employee.department, employee.designation, employee.company_email, employee.personal_email]
      .some((value) => String(value || '').toLowerCase().includes(query)),
  )
})
const activeCount = computed(() => (employees.data || []).filter((employee) => employee.status === 'Active').length)
const departmentCount = computed(() => new Set((employees.data || []).map((employee) => employee.department).filter(Boolean)).size)
const summaryCards = computed(() => [
  { label: 'Total employees', value: canReadEmployees.value ? employees.data?.length || 0 : '—', hint: 'in directory', icon: 'lucide-users-round' },
  { label: 'Active employees', value: canReadEmployees.value ? activeCount.value : '—', hint: 'currently active', icon: 'lucide-user-check' },
  { label: 'Departments', value: canReadEmployees.value ? departmentCount.value : '—', hint: 'represented', icon: 'lucide-building-2' },
  { label: 'HR workspace', value: 'India', hint: 'payroll region', icon: 'lucide-map-pin' },
])
const sectionDescription = computed(() => ({
  Attendance: 'Review attendance records and daily check-ins for your team.',
  Leave: 'Review leave applications and manage approvals.',
  Payroll: 'Review salary slips and payroll processing for India.',
}[activeTab.value]))

function initials(name) {
  return String(name || '?').split(/\s+/).slice(0, 2).map((part) => part[0]).join('').toUpperCase()
}

function formatDate(value) {
  if (!value) return '—'
  return new Intl.DateTimeFormat(undefined, { day: 'numeric', month: 'short', year: 'numeric' }).format(new Date(`${value}T00:00:00`))
}

function openEmployee(name = null) {
  if (name ? !canWriteEmployees.value : !canCreateEmployees.value) return
  showModal({
    name,
    doctype: 'Employee',
    title: 'Employee',
    defaults: { status: 'Active', date_of_joining: new Date().toISOString().slice(0, 10) },
    callbacks: { afterInsert: () => employees.reload(), afterUpdate: () => employees.reload() },
  })
}

function openHRMS(path = '/app/hr') {
  window.open(path, '_blank', 'noopener')
}
</script>
