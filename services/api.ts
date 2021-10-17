export const deleteRow = async (body: Record<string, unknown>) => {
  await fetch('/api/tables', {
    method: 'DELETE',
    body: JSON.stringify(body)
  })
}