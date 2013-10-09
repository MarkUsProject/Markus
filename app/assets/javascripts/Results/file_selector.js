function with_annotations() {
  if (document.getElementById('include_annotations').checked) {
    document.getElementById('download_zip').value = 'true';
  } else {
    document.getElementById('download_zip').value = 'false';
  }
}