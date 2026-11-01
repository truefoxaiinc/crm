export class CRMTask {
  onRender() {
    if (this.doc.reference_doctype && this.doc.reference_docname) {
      let label = this.doc.reference_doctype.replace('CRM ', '')

      this.actions = [
        {
          name: 'Redirect Action',
          label: __('Open {0}', [label]),
          onClick: (close) => {
            if (!this.doc.reference_docname) return
            let name =
              this.doc.reference_doctype == 'CRM Deal'
                ? 'Deal'
                : this.doc.reference_doctype == 'CRM Project'
                  ? 'Project'
                  : 'Lead'
            let params =
              name == 'Deal'
                ? { dealId: this.doc.reference_docname }
                : name == 'Project'
                  ? { projectId: this.doc.reference_docname }
                  : { leadId: this.doc.reference_docname }
            this.router.push({ name: name, params: params })
            close?.()
          },
        },
      ]
    }
  }
}
