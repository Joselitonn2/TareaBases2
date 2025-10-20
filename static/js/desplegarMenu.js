function desplegarMenu(menuId) {
  document.getElementById(menuId).classList.toggle('show');
}

window.addEventListener('click', function(event) {
  if (!event.target.matches('.menu-btn')) {
    var dropdowns = document.getElementsByClassName('dropdown-content');
    for (let i = 0; i < dropdowns.length; i++) {
      var openDropdown = dropdowns[i];
      if (openDropdown.classList.contains('show')) {
        openDropdown.classList.remove('show');
      }
    }
  }
});
