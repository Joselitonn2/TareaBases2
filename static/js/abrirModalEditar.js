const modal = { element: null };

function abrirModalEditar(empleadoId) {
    
    if (!modal.element) {
        modal.element = document.createElement('div');
        modal.element.id = 'modificarModal';
        modal.element.classList.add('modal-backdrop'); 
        

        modal.element.innerHTML = '<div id="modal-content-form" class="modal-dialog">Cargando...</div>'; 
        document.body.appendChild(modal.element);
    }

    const modalContent = document.getElementById('modal-content-form');
    modalContent.innerHTML = 'Cargando datos...';
    modal.element.style.display = 'flex'; 
    fetch('/empleadoEdicion/' + empleadoId)
        .then(response => {
            if (!response.ok) {
                
                throw new Error('Empleado o formulario no encontrado (' + response.status + ')');
            }
            return response.text(); 
        })
        .then(htmlForm => {
 
            modalContent.innerHTML = htmlForm;
        })
        .catch(error => {
            modalContent.innerHTML = `<p style="color:red;">Error al cargar: ${error.message}</p>`;
            console.error('Error:', error);
        });
}

function cerrarModalEditar() {

    if (modal.element) modal.element.style.display = 'none';
}


window.addEventListener('click', function (event) {
    if (modal.element && event.target === modal.element) {
        cerrarModalEditar();
    }
});
