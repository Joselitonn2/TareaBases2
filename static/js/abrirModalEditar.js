const modal = { element: null };

function abrirModalEditar(empleadoId) {
    // 1. Crear el contenedor principal del modal si no existe
    if (!modal.element) {
        modal.element = document.createElement('div');
        modal.element.id = 'modificarModal';
        modal.element.classList.add('modal-backdrop'); // Clase para el fondo gris
        
        // Contenedor interno que centrará el formulario
        modal.element.innerHTML = '<div id="modal-content-form" class="modal-dialog">Cargando...</div>'; 
        document.body.appendChild(modal.element);
    }

    const modalContent = document.getElementById('modal-content-form');
    modalContent.innerHTML = 'Cargando datos...';
    modal.element.style.display = 'flex'; // Usamos 'flex' para mostrar y centrar (requiere CSS)

    // 2. Fetch para obtener el HTML del formulario pre-llenado desde Flask
    fetch('/empleadoEdicion/' + empleadoId)
        .then(response => {
            if (!response.ok) {
                // Si Flask retorna 404, lanzamos error
                throw new Error('Empleado o formulario no encontrado (' + response.status + ')');
            }
            return response.text(); // Esperamos HTML como respuesta
        })
        .then(htmlForm => {
            // 3. Inyectar el HTML en el cuerpo del modal
            modalContent.innerHTML = htmlForm;
        })
        .catch(error => {
            modalContent.innerHTML = `<p style="color:red;">Error al cargar: ${error.message}</p>`;
            console.error('Error:', error);
        });
}

function cerrarModalEditar() {
    // Esencial: cerrar el modal
    if (modal.element) modal.element.style.display = 'none';
}

// 4. Cierra el modal al hacer clic en el fondo gris (fuera del contenido)
window.addEventListener('click', function (event) {
    if (modal.element && event.target === modal.element) {
        cerrarModalEditar();
    }
});
