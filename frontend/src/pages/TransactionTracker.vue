<template>
  <LayoutHeader>
    <template #left-header>
      <div class="text-2xl-semibold text-ink-gray-9">{{ __(title) }}</div>
    </template>
    <template #right-header>
      <Button
        variant="solid"
        :label="isCredit ? __('New Credit') : __('New Purchase')"
        iconLeft="lucide-plus"
        @click="openRecord()"
      />
    </template>
  </LayoutHeader>

  <div v-if="records.loading" class="flex h-full items-center justify-center">
    <LoadingIndicator class="size-6" />
  </div>
  <EmptyState
    v-else-if="!records.data?.length"
    :name="title"
    :icon="isCredit ? 'lucide-credit-card' : 'lucide-shopping-cart'"
    :title="isCredit ? __('No credit records yet') : __('No purchases yet')"
    :description="isCredit ? __('Track credit given or received, settlement progress, and due dates.') : __('Keep a simple record of supplier purchases, payments, and due dates.')"
    @create="openRecord()"
  />
  <div v-else class="flex h-full min-h-0 flex-col overflow-y-auto p-3 sm:p-5">
    <div class="mb-4 grid gap-3 sm:grid-cols-2">
      <div class="rounded-lg border border-outline-gray-2 bg-surface-white p-4">
        <div class="text-sm text-ink-gray-5">{{ isCredit ? __('Credit Records') : __('Purchases') }}</div>
        <div class="mt-1 text-2xl-semibold text-ink-gray-9">{{ records.data.length }}</div>
      </div>
      <div class="rounded-lg border border-outline-gray-2 bg-surface-white p-4">
        <div class="text-sm text-ink-gray-5">{{ isCredit ? __('Open Balance') : __('Unpaid Balance') }}</div>
        <div class="mt-1 text-2xl-semibold text-ink-gray-9">{{ formatAmount(outstandingTotal) }}</div>
      </div>
    </div>

    <div class="overflow-x-auto rounded-lg border border-outline-gray-2 bg-surface-white">
      <table class="w-full min-w-[850px] border-collapse text-left">
        <thead>
          <tr class="border-b border-outline-gray-1 bg-surface-gray-1 text-xs-medium uppercase tracking-wide text-ink-gray-5">
            <th class="px-4 py-3">{{ isCredit ? __('Credit') : __('Purchase') }}</th>
            <th class="px-4 py-3">{{ isCredit ? __('Person or Company') : __('Supplier') }}</th>
            <th v-if="isCredit" class="px-4 py-3">{{ __('Direction') }}</th>
            <th class="px-4 py-3">{{ isCredit ? __('Credit Date') : __('Purchase Date') }}</th>
            <th class="px-4 py-3 text-right">{{ __('Amount') }}</th>
            <th class="px-4 py-3 text-right">{{ isCredit ? __('Settled') : __('Paid') }}</th>
            <th class="px-4 py-3">{{ __('Status') }}</th>
            <th class="px-4 py-3">{{ __('Due Date') }}</th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="record in records.data"
            :key="record.name"
            class="cursor-pointer border-b border-outline-gray-1 text-sm last:border-b-0 hover:bg-surface-gray-1"
            @click="openRecord(record.name)"
          >
            <td class="px-4 py-3">
              <div class="font-medium text-ink-gray-9">{{ record.title }}</div>
              <div class="mt-0.5 text-xs text-ink-gray-5">{{ record.name }}</div>
            </td>
            <td class="px-4 py-3 text-ink-gray-7">{{ isCredit ? record.party : record.supplier }}</td>
            <td v-if="isCredit" class="px-4 py-3 text-ink-gray-7">{{ __(record.direction) }}</td>
            <td class="px-4 py-3 text-ink-gray-7">{{ formatDate(isCredit ? record.credit_date : record.purchase_date) || '—' }}</td>
            <td class="px-4 py-3 text-right text-ink-gray-8">{{ formatAmount(record.amount) }}</td>
            <td class="px-4 py-3 text-right text-ink-gray-8">{{ formatAmount(isCredit ? record.settled_amount : record.paid_amount) }}</td>
            <td class="px-4 py-3">
              <Badge
                variant="subtle"
                :theme="statusTheme(isCredit ? record.status : record.payment_status)"
                size="md"
                :label="__(isCredit ? record.status : record.payment_status)"
              />
            </td>
            <td class="px-4 py-3 text-ink-gray-7">{{ formatDate(record.due_date) || '—' }}</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p class="mt-3 text-xs text-ink-gray-5">{{ __('This tracker records purchases and credits only; it does not post accounting or payments.') }}</p>
  </div>
</template>

<script setup>
import EmptyState from '@/components/ListViews/EmptyState.vue'
import LoadingIndicator from '@/components/Icons/LoadingIndicator.vue'
import LayoutHeader from '@/components/LayoutHeader.vue'
import { useDoctypeModal } from '@/composables/doctypeModal'
import { getMeta } from '@/stores/meta'
import { formatDate as formatLocalDate } from '@/utils'
import { createListResource } from 'frappe-ui'
import { computed } from 'vue'

const props = defineProps({
  doctype: { type: String, required: true },
  title: { type: String, required: true },
})

const isCredit = computed(() => props.doctype === 'CRM Credit Record')
const fields = computed(() =>
  isCredit.value
    ? ['name', 'title', 'party', 'direction', 'credit_date', 'amount', 'settled_amount', 'status', 'due_date', 'modified']
    : ['name', 'title', 'supplier', 'purchase_date', 'amount', 'paid_amount', 'payment_status', 'due_date', 'modified'],
)
const records = createListResource({
  doctype: props.doctype,
  fields: fields.value,
  orderBy: 'modified desc',
  pageLength: 100,
  auto: true,
})
const { getFormattedCurrency } = getMeta(props.doctype)
const { showModal } = useDoctypeModal()

const outstandingTotal = computed(() =>
  (records.data || []).reduce((total, record) => {
    const settled = isCredit.value ? record.settled_amount : record.paid_amount
    return total + Math.max(Number(record.amount || 0) - Number(settled || 0), 0)
  }, 0),
)

function formatAmount(value) {
  return getFormattedCurrency('amount', { amount: Number(value || 0) })
}

function formatDate(value) {
  return value ? formatLocalDate(value) : ''
}

function statusTheme(status) {
  return {
    Unpaid: 'orange',
    'Partially Paid': 'blue',
    Paid: 'green',
    Open: 'orange',
    'Partially Settled': 'blue',
    Settled: 'green',
    Cancelled: 'gray',
  }[status] || 'gray'
}

function openRecord(name = null) {
  const creditDefaults = { direction: 'Credit Given', status: 'Open', settled_amount: 0 }
  const purchaseDefaults = { category: 'Other', payment_status: 'Unpaid', paid_amount: 0 }
  showModal({
    name,
    doctype: props.doctype,
    title: props.title,
    defaults: isCredit.value ? creditDefaults : purchaseDefaults,
    callbacks: {
      afterInsert: () => records.reload(),
      afterUpdate: () => records.reload(),
    },
  })
}
</script>
