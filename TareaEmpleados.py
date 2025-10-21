from flask import Flask, jsonify, render_template, request, redirect, flash
import pymssql 
import datetime
from pymssql import output 

app = Flask(__name__)
app.secret_key = 'qwerty'
conexion=pymssql.connect(
    server="25.1.54.2",       
    user="sa",
    password="382005ALH",
    database="Tarea2BD",
    autocommit=True
)

idSesion=0
@app.route('/')
def inicio():
    return redirect('/login')

@app.route('/login', methods=['POST','GET'])
def login():

    if request.method == 'POST':
        
        usuario = request.form.get('usuario') 
        contraseña = request.form.get('password')
        ipCliente = request.remote_addr 
        cursor = conexion.cursor()

        try:
            out_param = output(int) 

      
            loginSp ="LoginUsuario"

            params = (usuario, contraseña, ipCliente, out_param)


            cursor.callproc(loginSp, params)
            fila=cursor.fetchone()
            codigo_resultado = fila[0]
            print(f"Código de resultado del SP Login (pymssql): {codigo_resultado}")
            conexion.commit()

        except Exception as e:
            print(f"Error al ejecutar SP Login: {e}")

            flash("Ocurrió un error en el servidor. Intente más tarde.", 'error')
            codigo_resultado = 99999 
        finally:

            if cursor:
                cursor.close()

        if codigo_resultado == 0:
            global idSesion
            idSesion = fila[1]
            print(f"ID de sesión obtenido: {idSesion}")
            return redirect('/index') 
        elif codigo_resultado in (50001, 50002):
   
            flash("Credenciales inválidas. Intente de nuevo.", 'error')
        elif codigo_resultado == 50003:

            return render_template("login.html", inhabilitado=True) 
        else:
   
            flash("Error de validación desconocido. Código: {}".format(codigo_resultado), 'error')

        return render_template("login.html", inhabilitado=False)


    else:

        return render_template("login.html", inhabilitado=False)


@app.route('/index', methods=['GET', 'POST'])
def index():
    filtro = None
    if request.method == 'POST':
        filtro = request.form.get('filtro')


    cursor = conexion.cursor()
    print(f"Filtro recibido en /index: '{filtro}'")
    if filtro and filtro.strip():
        
        sql = "EXEC ListarEmpleado @TerminoBusqueda = %s"
        cursor.execute(sql, filtro)
    else:
        sql = "EXEC ListarEmpleado"
        cursor.execute(sql)

    filas = cursor.fetchall()
    empleados = [{"id": r[0],
                  "cedula": r[2], 
                  "nombre": r[1], 
                  "puesto": r[4], 
                  "saldo": r[3]} 
                  for r in filas]
    puestos=obtenerPuestosDisponibles(cursor)
    print(f"Puestos: {puestos}")
    cursor.close()
    return render_template("index.html", empleados=empleados, filtroActual=filtro, puestos=puestos)

@app.route('/listarMovimientos/<empleadoId>', methods=['GET'])
def listarMovimientos(empleadoId):
    """
    Ruta para mostrar la lista de movimientos de un empleado.
    El empleado_id de la URL corresponde a la columna m.IdEmpleado del SP.
    """
    cursor = conexion.cursor()
    movimientos = []
    nombreEmpleado = request.args.get('nombre', 'Desconocido')
    saldoEmpleado = request.args.get('saldo', '0.00')
    cedula= request.args.get('cedula', '000000000')
    tipoMovimiento = "SELECT Id, Nombre FROM dbo.TipoMovimiento ORDER BY Nombre"
    cursor.execute(tipoMovimiento)
    filasMovimientos = cursor.fetchall()
    tipos = [
        {"id": r[0], "nombre": r[1]} for r in filasMovimientos
    ]
    try:

        sp = "ListarMovimientos"
        idEmpleado = int(empleadoId)
        params = (idEmpleado,)
        cursor.callproc(sp, params)

        filas = cursor.fetchall()
        movimientos = [
        {
            "id_movimiento": r[0],
            "fecha": r[1].strftime('%Y-%m-%d %H:%M:%S') if r[1] else 'N/A', 
            "tipo": r[2], 
            "monto": r[3],
            "nuevoSaldo": r[4],
            "usuarioPost": r[5] if r[5] else 'Sistema',
            "ipPost": r[6],
            "tiempoPost": r[7].strftime('%Y-%m-%d %H:%M:%S') if r[7] else 'N/A' 
        } 
        for r in filas
    ]
        print(f"Movimientos obtenidos para empleado ID {empleadoId}: {movimientos}")
        
    except Exception as e:
        print(f"Error al listar movimientos para empleado ID {empleadoId}: {e}")
        flash("Hubo un error al cargar el historial de movimientos.", 'error')

        movimientos = []
        
    finally:
        if cursor:
            cursor.close()
    
    print(f"nombreEmpleado: {nombreEmpleado}, saldoEmpleado: {saldoEmpleado}, cedula: {cedula}")

    return render_template("listarMovimientos.html", 
                           empleadoId=empleadoId,
                           nombreEmpleado=nombreEmpleado,
                           movs=tipos,
                           saldoEmpleado=saldoEmpleado,
                           cedula=cedula,
                           movimientos=movimientos)

@app.route('/empleado/<int:empleado_id>', methods=['GET'])
def apiGetEmpleado(empleado_id):
    """
    Ruta API para obtener los datos de un empleado por su ID y devolverlos en JSON.
    """
    cursor = None
    datos = None
    
    try:
        cursor = conexion.cursor()

        sql = "EXEC ListarEmpleado @TerminoBusqueda = %s" 

        cursor.execute(sql, (empleado_id,))
        fila = cursor.fetchone()

        if fila:
           
            datos = {
                "nombre": fila[1],
                "cedula": fila[2],
                "saldoVacaciones": fila[3], # Saldo
                "puesto": fila[4],     # Puesto

            }
            print(f"Datos obtenidos para empleado ID {empleado_id}: {datos}")
        else:

            return jsonify({"error": "Empleado no encontrado"}), 404
            
    except Exception as e:
        print(f"Error en API al obtener empleado {empleado_id}: {e}")
        return jsonify({"error": "Error interno del servidor"}), 500
        
    finally:
        if cursor:
            cursor.close()
            
    return jsonify(datos)

@app.route('/insertar', methods=['POST'])
def insertar():
    cedula = request.form['cedula']
    nombre = request.form['nombre']
    puesto = int(request.form['puestoId'])
    IDPostByUser = int(idSesion)
    print(f"ID de sesión para inserción: {IDPostByUser}")
    ip= request.remote_addr
    IDNuevoEmpleado_out = output(int)
    codigo_resultado = output(int)
    fechaContratacion=datetime.datetime.now()
    params = (
        cedula,                
        nombre,              
        puesto,             
        fechaContratacion,    
        IDPostByUser,           
        ip,                    
        IDNuevoEmpleado_out,   
        codigo_resultado          
    )
    cursor=conexion.cursor()
    loginSp ="InsertarEmpleado"
    cursor.callproc(loginSp, params)
    fila=cursor.fetchone()
    codigo_resultado = fila[0]
    print(f"Código de resultado del SP InsertarEmpleado (pymssql): {codigo_resultado}")
    conexion.commit()
    try:
        if codigo_resultado ==0:
            flash("Empleado insertado exitosamente.", 'success')
            return redirect('/index')
        elif codigo_resultado ==50004:
            flash("Otro empleado con la misma cédula ya existe.", 'error')
        elif codigo_resultado ==50005:
            flash("Nombre duplicado, por favor intente con otro.", 'error')
        elif codigo_resultado ==50006:
            flash("Error: Puesto inválido.", 'error') 
    except Exception as e:
        print(f"No se ha podido insertar el empleado, intentelo de nuevo: {e}")
        flash("Ocurrió un error inesperado al insertar el empleado.", 'error')
    cursor.close()
    return redirect('/index')

def obtenerPuestosDisponibles(cursor):
    
    sql_puestos = "SELECT Id, Nombre FROM dbo.Puesto ORDER BY Nombre"
    cursor.execute(sql_puestos)
    filas_puestos = cursor.fetchall()
    
    puestos = [
        {"id": r[0], "nombre": r[1]} for r in filas_puestos
    ]
    return puestos

@app.route('/eliminarEmpleado', methods=['POST'])
def eliminarEmpleado():
    if request.method == 'POST':
        empleadoId = request.form.get('empleadoId')
        print(f"Empleado ID a eliminar: {empleadoId}")
        cursor = conexion.cursor()
        codigoResultado = 0
        ip=request.remote_addr
        params = (
            empleadoId,
            int(idSesion),
            ip,
            codigoResultado
        )
        try:
            sp = "EliminarEmpleadoLogico"
            cursor.callproc(sp, params)
            fila = cursor.fetchone()
            codigoResultado = fila[0]
            print(f"Código de resultado del SP EliminarEmpleado (pymssql): {codigoResultado}")
            conexion.commit()
            if codigoResultado == 0:
                flash("Empleado eliminado exitosamente.", 'success')
            elif codigoResultado == 50008:
                flash("No se puede eliminar el empleado porque tiene movimientos asociados.", 'error')        
        except Exception as e:
            flash("No se ha podido eliminar el empleado, intentelo de nuevo: {e}", 'error')  
        finally:
            if cursor:
                cursor.close()

    return redirect('/index')

@app.route('/empleadoEdicion/<int:empleado_id>', methods=['GET'])
def obtener_formulario_edicion(empleado_id):
    """
    Ruta llamada por JavaScript (fetch) que devuelve el HTML del formulario.
    """
    cursor = None
    empleado = None

    try:
        cursor = conexion.cursor()
        sql_empleado = "EXEC ListarEmpleado @TerminoBusqueda = %s" 
        cursor.execute(sql_empleado, (empleado_id,))
        fila_empleado = cursor.fetchone()
        
        if not fila_empleado:
            return "Empleado no encontrado", 404

        empleado = {
            "id": fila_empleado[0],
            "nombre": fila_empleado[1],
            "cedula": fila_empleado[2],
            "id_puesto_actual": fila_empleado[3],
            "puesto_nombre": fila_empleado[4]
        }
        
        
        puestosDisponibles = obtenerPuestosDisponibles(cursor)

    except Exception as e:
        print(f"Error al obtener formulario de edición para ID {empleado_id}: {e}")
        return "Error interno del servidor", 500
        
    finally:
        if cursor:
            cursor.close()

    return render_template("editarEmpleado.html", 
                           empleado=empleado, 
                           puestos=puestosDisponibles)

@app.route('/insertarMovimiento/<int:empleadoId>', methods=['POST'])
def insertarMovimiento(empleadoId):
    tipoMovimientoId = int(request.form['movId'])
    monto = float(request.form['monto'])
    IDPostByUser = int(idSesion)
    fecha=datetime.datetime.now()
    print(f"ID de sesión para inserción de movimiento: {IDPostByUser}")
    ip= request.remote_addr
    codigoResultado = 5
    params = (
        empleadoId,                
        tipoMovimientoId,
        fecha,             
        monto,             
        IDPostByUser,           
        ip,                    
        codigoResultado          
    )
    print(f"Parámetros para InsertarMovimiento: {params}")
    cursor=conexion.cursor()
    sp ="InsertarMovimiento"
    cursor.callproc(sp, params)
    fila=cursor.fetchone()
    codigoResultado = fila[0]
    print(f"Código de resultado del SP InsertarMovimiento (pymssql): {codigoResultado}")
    try:
        if codigoResultado ==0:
            flash("Movimiento insertado exitosamente.", 'success')
        elif codigoResultado==50011:
            flash("Monto inválido para el tipo de movimiento.", 'error')
        elif codigoResultado==50008:
            flash("Ha ocurrido un error, intentelo de nuevo.", 'error') 
    except Exception as e:
        print(f"No se ha podido insertar el movimiento, intentelo de nuevo: {e}")
        flash("Ocurrió un error inesperado al insertar el movimiento.", 'error')
    cursor.close()
    return redirect("/index")

@app.route('/guardarModificacion', methods=['POST'])
def guardarModificacion():
    if request.method == 'POST':
        empleadoId = int(request.form.get('empleadoId'))
        nuevoNombre = request.form.get('nombre')
        nuevaCedula = request.form.get('cedula')
        nuevoPuestoId = int(request.form.get('puestoId'))
        print(f"Datos recibidos para modificar empleado ID {empleadoId}: Nombre={nuevoNombre}, Cédula={nuevaCedula}, PuestoID={nuevoPuestoId}")
        cursor = conexion.cursor()
        codigoResultado = 0
        ip=request.remote_addr
        params = (
            empleadoId,
            nuevaCedula,
            nuevoNombre,
            nuevoPuestoId,
            int(idSesion),
            ip,
            codigoResultado
        )
        try:
            sp = "ActualizarEmpleado"
            cursor.callproc(sp, params)
            fila = cursor.fetchone()
            codigoResultado = fila[0]
            print(f"Código de resultado del SP ModificarEmpleado (pymssql): {codigoResultado}")
            conexion.commit()
            if codigoResultado == 0:
                flash("Empleado modificado exitosamente.", 'success')
            elif codigoResultado == 50010:
                flash("Formato de cedula incorrecto.", 'error')
            elif codigoResultado == 50009:
                flash("Formato de nombre incorrecto.", 'error')
            elif codigoResultado == 50006:
                flash("La cedula que se quiere registrar ya existe", 'error')
            elif codigoResultado == 50007:
                flash("El usuario que se quiere registrar ya existe", 'error') 
        except Exception as e:
            flash("No se ha podido modificar el empleado, intentelo de nuevo: {e}", 'error')  
        finally:
            if cursor:
                cursor.close()

    return redirect('/index')


if __name__ == '__main__':
    app.run(host='25.1.48.153', port=5000, debug=True)