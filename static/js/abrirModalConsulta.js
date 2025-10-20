function abrirModalConsulta(id) {
    mostrarConsultaModal(id);
}

function mostrarConsultaModal(id) {
    fetch('/empleado/' + id)
        .then(response => {
            if (!response.ok) {
                throw new Error('Empleado no encontrado. Código: ' + response.status);
            }
            return response.json();
        })
        .then(data => {
            document.getElementById('modal_cedula').textContent = data.cedula;
            document.getElementById('modal_nombre').textContent = data.nombre;
            document.getElementById('modal_puesto').textContent = data.puesto || '';
            document.getElementById('modal_vacaciones').textContent = (data.saldoVacaciones || 0) + ' días';
            document.getElementById('modalConsulta').style.display = 'block';
        })
        .catch(error => {
            console.error('Error al obtener los datos:', error);
            alert('Error al cargar la información del empleado: ' + error.message);
        });
}

function cerrarModalConsulta() {
    document.getElementById('modalConsulta').style.display = 'none';
}
