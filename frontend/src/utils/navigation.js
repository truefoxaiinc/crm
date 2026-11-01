import ContactsIcon from '@/components/Icons/ContactsIcon.vue'
import DealsIcon from '@/components/Icons/DealsIcon.vue'
import LeadsIcon from '@/components/Icons/LeadsIcon.vue'
import NoteIcon from '@/components/Icons/NoteIcon.vue'
import OrganizationsIcon from '@/components/Icons/OrganizationsIcon.vue'
import PhoneIcon from '@/components/Icons/PhoneIcon.vue'
import TaskIcon from '@/components/Icons/TaskIcon.vue'
import LucideLayoutDashboard from '~icons/lucide/layout-dashboard'
import LucideBriefcaseBusiness from '~icons/lucide/briefcase-business'
import LucideShoppingCart from '~icons/lucide/shopping-cart'
import LucideCreditCard from '~icons/lucide/credit-card'
import LucideUsersRound from '~icons/lucide/users-round'
import router from '@/router'

export const navigationItems = [
  {
    label: 'Dashboard',
    icon: LucideLayoutDashboard,
    route: 'Dashboard',
    desktopOnly: true,
  },
  { label: 'Leads', icon: LeadsIcon, route: 'Leads' },
  { label: 'Deals', icon: DealsIcon, route: 'Deals' },
  { label: 'Contacts', icon: ContactsIcon, route: 'Contacts' },
  { label: 'Organizations', icon: OrganizationsIcon, route: 'Organizations' },
  { label: 'Notes', icon: NoteIcon, route: 'Notes' },
  { label: 'Tasks', icon: TaskIcon, route: 'Tasks' },
  { label: 'Projects', icon: LucideBriefcaseBusiness, route: 'Projects' },
  { label: 'Purchases', icon: LucideShoppingCart, route: 'Purchases' },
  { label: 'Credits', icon: LucideCreditCard, route: 'Credits' },
  { label: 'HR & Payroll', icon: LucideUsersRound, route: 'HR & Payroll' },
  { label: 'Call Logs', icon: PhoneIcon, route: 'Call Logs' },
]

export function getNavigationItems({ mobile = false } = {}) {
  return navigationItems.filter(
    (item) => router.hasRoute(item.route) && (!mobile || !item.desktopOnly),
  )
}
