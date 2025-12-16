import tkinter as tk
from tkinter import messagebox
import subprocess

FREEIPA_REALM = "IAM.LAB"


def authenticate():
    username = entry_username.get().strip()
    password = entry_password.get().strip()

    if not username or not password:
        messagebox.showerror("Error", "Please enter both username and password.")
        return

    try:
        proc = subprocess.run(
            ["kinit", username],
            input=f"{password}\n",
            text=True,
            capture_output=True,
            timeout=5
        )
        if proc.returncode == 0:
            messagebox.showinfo("Success", f"User {username} successfully authenticated.")
            root.destroy()  # zatvara login prozor
            # ovdje se može otvoriti novi "success" window ili izvršavati naredbe
        else:
            output = proc.stderr.lower()
            if "password incorrect" in output or "failed to obtain" in output:
                messagebox.showerror("Authentication Failed", "Incorrect password.")
            elif "account locked" in output or "preauth failed" in output:
                messagebox.showerror("Account Locked", "User account is locked due to failed login attempts.")
            else:
                messagebox.showerror("Authentication Failed", f"Error: {proc.stderr.strip()}")
    except subprocess.TimeoutExpired:
        messagebox.showerror("Timeout", "Authentication request timed out.")
    except Exception as e:
        messagebox.showerror("Error", str(e))


root = tk.Tk()
root.title("FreeIPA Login")
root.geometry("350x200")
root.resizable(False, False)

tk.Label(root, text="Username:").pack(pady=(20,5))
entry_username = tk.Entry(root, width=30)
entry_username.pack()

tk.Label(root, text="Password:").pack(pady=(10,5))
entry_password = tk.Entry(root, show="*", width=30)
entry_password.pack()

btn_login = tk.Button(root, text="Login", command=authenticate)
btn_login.pack(pady=20)

root.mainloop()
