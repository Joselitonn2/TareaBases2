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

@app.route('/')

def index():
    cursor=conexion.cursor()
    cursor.execute("{CALL ObtenerEmpleados}")
    filas=cursor.fetchall()
    empleados=[{"ID": r[0], "nombre": r[1], "salario": r[2]} for r in filas]
    cursor.close()
    return render_template("index.html", empleados=empleados)

@app.route('/insertar', methods=['POST'])
def insertar():
    nombre = request.form['nombre']
    salario = request.form['salario']

    cursor=conexion.cursor()
    cursor.execute("{CALL InsertarEmpleado(?,?)}",(nombre, salario))
    conexion.commit()
    cursor.close()
    return redirect('/')

if __name__ == '__main__':
    app.run(debug=True)