import frappe
from frappe import _
from frappe.model.document import Document
from frappe.utils import flt, getdate


class CRMCreditRecord(Document):
	def validate(self):
		if flt(self.amount) <= 0:
			frappe.throw(_("Amount must be greater than zero."))

		if flt(self.settled_amount) < 0 or flt(self.settled_amount) > flt(self.amount):
			frappe.throw(_("Settled Amount must be between zero and the credit amount."))

		if self.credit_date and self.due_date and getdate(self.due_date) < getdate(self.credit_date):
			frappe.throw(_("Due Date cannot be before Credit Date."))

		if self.status != "Cancelled":
			if flt(self.settled_amount) >= flt(self.amount):
				self.status = "Settled"
			elif flt(self.settled_amount) > 0:
				self.status = "Partially Settled"
			else:
				self.status = "Open"
