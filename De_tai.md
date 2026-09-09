# MẪU

# **BÁO CÁO MẪU DỰ ÁN CÔNG NGHỆ THÔNG TIN DÀNH CHO SINH VIÊN**

**Tài liệu này tổng hợp cấu trúc tiêu chuẩn cho 2 giai đoạn chính của một dự án công nghệ thông tin:** Giai đoạn Khởi tạo (Project Proposal) và Giai đoạn Thiết kế Hệ thống (System Analysis & Architectural Design). Sinh viên áp dụng mẫu này để hoàn thiện báo cáo đồ án / bài tập lớn theo từng tiến độ.

## **PHẦN 1: BÁO CÁO ĐỀ XUẤT DỰ ÁN (PROJECT PROPOSAL REPORT \- INITIATION PHASE)**

### **1.1. Tên dự án (Project Title)**

Nêu rõ ràng, ngắn gọn và chính xác tên của dự án/hệ thống sẽ xây dựng.

### **1.2. Danh sách thành viên và phân công vai trò (Team Members and Roles)**

| STT | Mã số sinh viên | Họ và tên | Vai trò & Trách nhiệm chính   |
| :---- | :---- | :---- | :---- |
| 1 | \[MSSV 1\] | \[Sinh viên 1\] | Thành viên chính (Project Manager / Fullstack) |
| 2 | \[MSSV 2\] | \[Sinh viên 2\] | Lập trình Backend (Backend Developer) |
| 3 | \[MSSV 3\] | \[Sinh viên 3\] | Lập trình Frontend (Frontend Developer) |
| 4 | \[MSSV 4\] | \[Sinh viên 4\] | Thiết kế giao diện / Kiểm thử (UI/UX & QA) |

### **1.3. Mục tiêu và Kết quả dự kiến (Objectives and Expected Outcomes)**

> * **Mục tiêu dự án:** Xác định rõ những gì dự án cần đạt được (ví dụ: xây dựng ứng dụng web quản lý bán hàng, ứng dụng di động theo dõi sức khỏe...).  
> * **Kết quả/Sản phẩm bàn giao dự kiến (Deliverables):** Liệt kê cụ thể các sản phẩm hoàn thành ở cuối dự án (mã nguồn, tài liệu thiết kế, file cài đặt, báo cáo thử nghiệm...).

### **1.4. Phạm vi dự án và Yêu cầu kỹ thuật (Scope and Technical Requirements)**

> * **Phạm vi dự án (Scope):**  
  * *Tính năng bao gồm (In-scope):* Các chức năng trọng tâm sẽ phát triển.  
  * *Tính năng không bao gồm (Out-of-scope):* Các chức năng/giới hạn không triển khai trong khuôn khổ đồ án này.  
> * **Yêu cầu kỹ thuật (Technical Requirements):** Ràng buộc về hiệu năng, bảo mật, nền tảng hỗ trợ, công nghệ áp dụng.

### **1.5. Kế hoạch triển khai ban đầu (Initial Implementation Plan)**

Mô tả kế hoạch thực hiện cấp cao bao gồm các giai đoạn, mốc quan trọng (milestones), hoạt động chính, thời hạn (deadlines) và phân công người chịu trách nhiệm.

### **1.6. Tài nguyên và Công cụ (Resources and Tools)**

> * **Công cụ & Công nghệ:** Phần mềm, Framework, thư viện, IDE sử dụng trong dự án.  
> * **Thao tác khởi tạo hạ tầng ban đầu:**  
  * Tạo kho lưu trữ mã nguồn (GitHub / GitLab Repository).  
  * Thiết lập luồng tự động hóa CI/CD ban đầu.  
  * Chuẩn bị môi trường phát triển (Development / Staging Environment).

### **1.7. Đánh giá rủi ro (Risk Assessment)**

Nhận diện các rủi ro có thể gặp phải (kỹ thuật, nhân sự, tiến độ) và đề xuất giải pháp giảm thiểu tương ứng.

### **1.8. Tài liệu tham khảo (References \- Nếu có)**

Liệt kê các nguồn tài liệu, sách, trang web hoặc nghiên cứu đã tham khảo khi lập đề xuất dự án.

## **PHẦN 2: BÁO CÁO PHÂN TÍCH HỆ THỐNG VÀ THIẾT KẾ KIẾN TRÚC (SYSTEM ANALYSIS & ARCHITECTURAL DESIGN REPORT \- DESIGN PHASE)**

### **2.1. Tổng quan hệ thống (System Overview)**

> * Mô tả ngắn gọn mục đích và các chức năng cốt lõi của hệ thống.  
> * Xác định đối tượng người dùng mục tiêu (Intended Users) và nền tảng triển khai (Target Platform).

### **2.2. Sơ đồ UML (UML Diagrams)**

Cung cấp các biểu đồ thiết kế UML kèm theo mô tả chi tiết cho từng sơ đồ (có thể sử dụng công cụ AI để hỗ trợ khởi tạo):

> * **Sơ đồ Use Case (Use Case Diagram):** Thể hiện tác nhân và các chức năng hệ thống.  
> * **Sơ đồ Lớp (Class Diagram):** Thiết kế cấu trúc các lớp và mối quan hệ giữa chúng.  
> * **Sơ đồ Tuần tự (Sequence Diagram):** Thể hiện luồng tương tác giữa các đối tượng theo thời gian cho các chức năng chính.

### **2.3. Thiết kế Cơ sở dữ liệu (Database Design)**

> * **Sơ đồ thực thể liên kết (ERD \- Entity-Relationship Diagram):** Cấu trúc dữ liệu tổng quan.  
> * **Lược đồ CSDL và Mô tả chi tiết các bảng (Schema & Tables):** Mô tả tên bảng, trường dữ liệu, kiểu dữ liệu, khóa chính, khóa ngoại và ràng buộc.

### **2.4. Thiết kế Giao diện Người dùng (UI Mockups)**

> * Đính kèm hình ảnh phác thảo/mockup của các màn hình trọng tâm.  
> * Mô tả lý do thiết kế (Design Rationale) và luồng thao tác của người dùng (User Flow).  
> * Figmar/MS word \---- de lam mockup va wireframe \----

### **2.5. Kế hoạch triển khai Test luong(hoac CI/CD)**

Phần CI/CD do **Thắng** phụ trách đã được thiết kế và triển khai bằng GitHub Actions. Nội dung chi tiết, luồng kiểm thử, chiến lược nhánh, cách phát hành và tiêu chí hoàn thành được trình bày tại [`docs/CI_CD.md`](docs/CI_CD.md).

Các pipeline đã triển khai:

- CI: kiểm tra format, phân tích tĩnh, chạy unit/widget test, tạo coverage và build APK cho pull request/push.
- CD: kiểm thử lại, build release APK và tự động tạo GitHub Release khi nhóm đẩy tag phiên bản dạng `vX.Y.Z`.

### **2.6. Mức độ đóng góp của thành viên (Team Contributions)**

Thống kê cụ thể các phần việc trong giai đoạn thiết kế mà từng thành viên trong nhóm đảm nhận và hoàn thành.

# TỔNG QUAN

### **Tiến độ BTL 1: Hết phần demo giao diện UI/UX (tuần 9 \- 6/10)**

### **1.1. Tên dự án (Project Title)**

Ứng dụng Quản lý Phân kỳ Trả nợ và báo cáo sức khỏe tín dụng cá nhân

### **1.2. Danh sách thành viên và phân công vai trò (Team Members and Roles)**

| Tên | CV (tiến độ 2\) | Đề mục | Deadline |
| :---- | :---- | :---- | :---- |
| Bình | Full Stack, Triển khai | Bao quát phần 2 | Giao diện demo 6/10 (tuần 9\) |
| Thúy | QA, Tester, BA | 2.1 \+ 2.5 |  |
| Lộc | FE, UI/UX ,tiến độ phần 1 | Phần 1 \+ 2.4 | P1. 13/9 (tuần 6), GD 29/9 (tuần 8\) |
| Quý | FE, BA | 2.2 \+ 2.4 | 29/9 Tuần 8 |
| Thắng | BE, DB | 2.5 |  |
| Tuấn\* | DB (mySQL), BE | 2.3 | 20/9 (giữa tuần 7\) |

### **1.3. Mục tiêu và Kết quả dự kiến (Objectives and Expected Outcomes)**

**1.4. Phạm vi dự án và Yêu cầu kỹ thuật (Scope and Technical Requirements)**

### **1.5. Kế hoạch triển khai ban đầu (Initial Implementation Plan)**

### **1.6. Tài nguyên và Công cụ (Resources and Tools)**

\<Bình\>

### **1.7. Đánh giá rủi ro (Risk Assessment)**

### **1.8. TLTK**

\* Sau khi thiết kế CSDL xong, sửa file mock\_data, dựa vào file này thiết UI/UX  
Đầu ra FE: mô tả trang (tên gì, có những gì bên trong), giao diện màu sắc, ảnh bố cục  
Viết widget  
Tự tạo nhánh git để commit, main chính để Bình commit chính

# PHẦN 1
