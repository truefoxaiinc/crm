import frappe
from frappe import _
from frappe.model.document import Document
from frappe.utils import getdate


class CRMProject(Document):
	def validate(self):
		if self.start_date and self.expected_end_date:
			if getdate(self.expected_end_date) < getdate(self.start_date):
				frappe.throw(_("Expected End Date cannot be before Start Date."))

	@staticmethod
	def default_list_data():
		return {
			"columns": [
				{"label": "Project", "type": "Data", "key": "project_name", "width": "16rem"},
				{"label": "Status", "type": "Select", "key": "status", "width": "9rem"},
				{"label": "Priority", "type": "Select", "key": "priority", "width": "8rem"},
				{"label": "Start Date", "type": "Date", "key": "start_date", "width": "9rem"},
				{"label": "Expected End", "type": "Date", "key": "expected_end_date", "width": "9rem"},
				{"label": "Progress", "type": "Percent", "key": "progress", "width": "8rem"},
				{"label": "Project Manager", "type": "Link", "key": "project_manager", "options": "User", "width": "12rem"},
			],
			"rows": [
				"name", "project_name", "status", "priority", "start_date",
				"expected_end_date", "progress", "project_manager", "lead",
				"deal", "contact", "organization", "modified",
			],
		}
