\# Rancangan DonorKu



\## Role

\- \*\*Pendonor\*\*: mengisi profil donor (golongan darah, rhesus, lokasi), melihat

&#x20; permintaan yang cocok, dan menyatakan bersedia mendonor.

\- \*\*Pemohon\*\*: membuat permintaan darah, memantau pendonor yang bersedia,

&#x20; dan menyetujui pendonor.

\- \*\*Admin\*\*: memverifikasi atau menolak permintaan sebelum disebarkan.



\## Rancangan tabel (awal)

| Tabel | Isi utama |

|---|---|

| `users` | nama, email, password, phone, role |

| `donor\_profiles` | user\_id, golongan darah, rhesus, latitude, longitude, tanggal donor terakhir, status bersedia |

| `blood\_requests` | pemohon, golongan darah, rhesus, jumlah kantong, rumah sakit, koordinat, batas waktu, status, waktu verifikasi |

| `request\_responses` | permintaan, pendonor, status (ditawarkan, disetujui, ditolak, selesai) |

| `donation\_histories` | pendonor, permintaan, tanggal donor |



\## Alur utama

1\. Pemohon membuat permintaan, status awal: menunggu verifikasi.

2\. Admin memverifikasi atau menolak permintaan.

3\. Sistem mencocokkan pendonor berdasarkan kompatibilitas golongan darah,

&#x20;  kelayakan donor, dan jarak.

4\. Pendonor menyatakan bersedia, lalu pemohon menyetujui.

5\. Setelah donor selesai, permintaan terpenuhi dan riwayat tercatat.



\## Prioritas fitur

\- \*\*Inti\*\*: login tiga role, profil donor, buat permintaan, verifikasi admin,

&#x20; pencocokan golongan darah, respons pendonor.

\- \*\*Menengah\*\*: kelayakan otomatis dari riwayat donor, urutan berdasarkan jarak,

&#x20; status permintaan, riwayat donor.

\- \*\*Lanjutan\*\*: notifikasi, peta, statistik.



\## Catatan

Aturan jeda antar donor dan syarat kelayakan mengacu pada ketentuan resmi

(sumber akan dicantumkan). Aplikasi ini penghubung, bukan pengganti

pemeriksaan medis.

