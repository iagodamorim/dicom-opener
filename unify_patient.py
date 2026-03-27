#!/usr/bin/env python3
"""
unify_patient.py
Extrai um ZIP DICOM, verifica se o paciente já existe no OsiriX,
unifica o Patient ID nos arquivos DICOM E no banco do OsiriX.

Uso: unify_patient.py <arquivo.zip>
Retorna: caminho da pasta com os DICOMs prontos para abrir no OsiriX
"""

import sys
import os
import sqlite3
import zipfile
import tempfile
import shutil

import pydicom
from pydicom.errors import InvalidDicomError


OSIRIX_DB = os.path.expanduser(
    "~/Documents/OsiriX Data.nosync/Database.sql"
)


def read_first_dicom(folder):
    """Lê o primeiro arquivo DICOM válido de uma pasta (recursivo)."""
    for root, _, files in os.walk(folder):
        for f in files:
            filepath = os.path.join(root, f)
            try:
                ds = pydicom.dcmread(filepath, stop_before_pixels=True)
                name = str(getattr(ds, "PatientName", "")).strip()
                dob = str(getattr(ds, "PatientBirthDate", "")).strip()
                pid = str(getattr(ds, "PatientID", "")).strip()
                if name:
                    return {"name": name, "dob": dob, "pid": pid}
            except (InvalidDicomError, Exception):
                continue
    return None


def find_existing_patient(name, dob):
    """Busca paciente existente no OsiriX pelo nome + data de nascimento."""
    if not os.path.exists(OSIRIX_DB):
        return None

    try:
        conn = sqlite3.connect(OSIRIX_DB)
        cursor = conn.cursor()
        cursor.execute(
            "SELECT ZPATIENTID, ZPATIENTUID FROM ZSTUDY "
            "WHERE ZNAME = ? AND ZDATEOFBIRTHSTRING = ? "
            "ORDER BY ZDATEADDED ASC LIMIT 1",
            (name, dob),
        )
        row = cursor.fetchone()
        conn.close()
        if row:
            return {"pid": row[0], "uid": row[1]}
    except Exception:
        pass
    return None


def unify_osirix_db(name, dob, target_pid, target_uid):
    """Atualiza TODOS os estudos do paciente no banco do OsiriX
    para usar o mesmo PatientID e PatientUID."""
    if not os.path.exists(OSIRIX_DB):
        return 0

    try:
        conn = sqlite3.connect(OSIRIX_DB)
        cursor = conn.cursor()
        cursor.execute(
            "UPDATE ZSTUDY SET ZPATIENTID = ?, ZPATIENTUID = ? "
            "WHERE ZNAME = ? AND ZDATEOFBIRTHSTRING = ? "
            "AND (ZPATIENTID != ? OR ZPATIENTUID != ?)",
            (target_pid, target_uid, name, dob, target_pid, target_uid),
        )
        updated = cursor.rowcount
        conn.commit()
        conn.close()
        return updated
    except Exception as e:
        print(f"DB error: {e}", file=sys.stderr)
        return 0


def modify_dicoms(folder, new_pid):
    """Altera o Patient ID em todos os DICOMs de uma pasta."""
    count = 0
    for root, _, files in os.walk(folder):
        for f in files:
            filepath = os.path.join(root, f)
            try:
                ds = pydicom.dcmread(filepath)
                if hasattr(ds, "PatientID") and str(ds.PatientID) != new_pid:
                    ds.PatientID = new_pid
                    ds.save_as(filepath)
                    count += 1
            except (InvalidDicomError, Exception):
                continue
    return count


def main():
    if len(sys.argv) < 2:
        print("Uso: unify_patient.py <arquivo.zip>")
        sys.exit(1)

    zip_path = sys.argv[1]
    if not os.path.exists(zip_path):
        print(f"Arquivo não encontrado: {zip_path}")
        sys.exit(1)

    # Extrai ZIP para pasta temporária
    extract_dir = tempfile.mkdtemp(prefix="dicom_")
    try:
        with zipfile.ZipFile(zip_path, "r") as zf:
            zf.extractall(extract_dir)
    except zipfile.BadZipFile:
        print("ZIP inválido")
        shutil.rmtree(extract_dir)
        sys.exit(1)

    # Lê info do paciente do DICOM
    info = read_first_dicom(extract_dir)
    if not info:
        print("Nenhum DICOM válido encontrado no ZIP")
        print(extract_dir)
        sys.exit(0)

    # Busca paciente existente no OsiriX
    existing = find_existing_patient(info["name"], info["dob"])

    if existing and existing["pid"] != info["pid"]:
        # 1. Modifica os novos DICOMs para usar o ID existente
        modified = modify_dicoms(extract_dir, existing["pid"])

        # 2. Unifica TODOS os estudos antigos no banco do OsiriX
        db_updated = unify_osirix_db(
            info["name"], info["dob"],
            existing["pid"], existing["uid"],
        )

        # 3. Re-zipa os DICOMs modificados
        new_zip = zip_path + ".unified.zip"
        with zipfile.ZipFile(new_zip, "w", zipfile.ZIP_DEFLATED) as zf:
            for root, _, files in os.walk(extract_dir):
                for f in files:
                    full = os.path.join(root, f)
                    arcname = os.path.relpath(full, extract_dir)
                    zf.write(full, arcname)

        shutil.rmtree(extract_dir)

        print(
            f"UNIFIED|{info['name']}|{info['pid']}>{existing['pid']}"
            f"|{modified} files|{db_updated} db records",
            file=sys.stderr,
        )
        # Retorna o ZIP unificado
        print(new_zip)
    else:
        shutil.rmtree(extract_dir)
        print(
            f"OK|{info['name']}|{info['pid']}|no change needed",
            file=sys.stderr,
        )
        # Sem mudança, usa o ZIP original
        print(zip_path)


if __name__ == "__main__":
    main()
