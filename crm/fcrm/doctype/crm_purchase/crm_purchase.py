import frappe
from frappe import _
from frappe.model.document import Document
from frappe.utils import flt, getdate


class CRMPurchase(Document):
	def validate(self):
		if flt(self.amount) <= 0:
			frappe.throw(_("Amount must be greater than zero."))

		if flt(self.paid_amount) < 0 or flt(self.paid_amount) > flt(self.amount):
			frappe.throw(_("Paid Amount must be between zero and the purchase amount."))

		if self.purchase_date and self.due_date and getdate(self.due_date) < getdate(self.purchase_date):
			frappe.throw(_("Due Date cannot be before Purchase Date."))

		if self.payment_status != "Cancelled":
			if flt(self.paid_amount) >= flt(self.amount):
				self.payment_status = "Paid"
			elif flt(self.paid_amount) > 0:
				self.payment_status = "Partially Paid"
			else:
				self.payment_status = "Unpaid"
