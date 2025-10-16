
  function toggleMenu(menuId) {
    // 1. Alterna la clase 'show' solo en el menú clickeado
    document.getElementById(menuId).classList.toggle("show");
  }

  // Cierra los menús si se hace clic fuera de ellos (Mejora de UX)
  window.onclick = function(event) {
    if (!event.target.matches('.menu-btn')) {
      var dropdowns = document.getElementsByClassName("dropdown-content");
      for (let i = 0; i < dropdowns.length; i++) {
        var openDropdown = dropdowns[i];
        // 2. Cierra cualquier otro menú que esté abierto
        if (openDropdown.classList.contains('show')) {
          openDropdown.classList.remove('show');
        }
      }
    }
  }