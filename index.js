window.onload = () => {
  if (location.search.includes('start')) {
    alert('SHOW INTRO');
    location.search = '';
  }
};
