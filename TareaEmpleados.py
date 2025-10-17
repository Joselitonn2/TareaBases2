from flask import Flask, render_template, request, redirect
import pyodbc

app = Flask(__name__)

conexion=pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=25.1.54.2;"        
    "DATABASE=Tarea1BD;"
    "UID=sa;"
    "PWD=382005ALH;"
)


@app.route('/login', methods=['POST'])
def login():
    usuario = request.form['username']
    contraseña = request.form['password']
    ipCliente = request.remote_addr 

    cursor = conexion.cursor()
    codigo_resultado = 99999 

    try:
        
        loginSp= "{CALL Login(?, ?, ?, ?)}"
        
        cursor.execute(loginSp, (usuario, contraseña, ipCliente, cursor))
        codigo_resultado = cursor.get_proc_return_code()

    except Exception as e:
        print(f"Error al ejecutar SP Login: {e}")
        codigo_resultado = 99999 
    finally:
        cursor.close()

  
    if codigo_resultado == 0:
        return redirect('/')
    elif codigo_resultado in (50001, 50002):
        # 50001: Usuario no existe; 50002: Contraseña inválida
        return "Credenciales inválidas", 401
    elif codigo_resultado == 50003:
        # 50003: Deshabilitado por demasiados intentos (el SP ya registró el evento)
        mensaje = "Demasiados intentos de login, intente de nuevo dentro de 10 minutos."
        return mensaje, 429 
    else:
        # Manejo de cualquier otro valor
        return "Error de validación desconocido", 500


@app.route('/')
def index():
    cursor=conexion.cursor()
    cursor.execute("EXEC ListarEmpleado")
    filas=cursor.fetchall()
    empleados=[{"cedula": r[0], "nombre": r[1], "puesto": r[2], "saldo": r[3]} for r in filas]
    cursor.close()
    return render_template("index.html", empleados=empleados)

@app.route('/filtro', methods=['POST'])
def filtro():
    filtro = request.form['filtro']
    cursor=conexion.cursor()
    cursor.execute("EXEC ListarEmpleado @Filtro = ?", filtro)
    filas=cursor.fetchall()
    empleados=[{"cedula": r[0], "nombre": r[1], "puesto": r[2], "saldo": r[3]} for r in filas]
    cursor.close()
    return render_template("index.html", empleados=empleados)

@app.route('/insertar', methods=['POST'])
def insertar():
    cedula = request.form['cedula']
    nombre = request.form['nombre']
    cursor=conexion.cursor()
    cursor.execute("{CALL InsertarEmpleado(?,?)}",(nombre, cedula))
    conexion.commit()
    cursor.close()
    return redirect('/')




if __name__ == '__main__':
    app.run(debug=True)