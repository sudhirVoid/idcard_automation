# 📊 Excel Upload Format

## Required Excel Structure

Your Excel file must have these **column headers** (order doesn't matter):

### **Required Columns:**
| Header Name | Alternative Names | Required | Description | Example |
|-------------|-------------------|----------|-------------|---------|
| **Class** | Grade, Standard | ✅ Required | Class number | 10, 11, 12 |
| **Name** | Student Name, Student_Name | ✅ Required | Student's full name | Radha Kawar |

### **Optional Columns:**
| Header Name | Alternative Names | Required | Description | Example |
|-------------|-------------------|----------|-------------|---------|
| **Section** | Division | ❌ Optional | Section name (defaults to "Default" if empty) | Darwin, Einstein, Newton |
| **Address** | - | ❌ Optional | Student's address | Rajpur-2, Materiya |
| **Parents** | Parent, Parent Name, Parent_Name | ❌ Optional | Parent/Guardian name | Shib Prasad Kawar |
| **Contact** | Phone, Mobile, Contact Number, Contact_Number | ❌ Optional | Phone number | 9869416392 |
| **Bus** | Bus Route, Bus_Route | ❌ Optional | Bus route information | Gadhawa(Buddha Chowk) |
| **S.N** | S.N., Serial No, Serial_No, Roll No, Roll_No, Roll Number, Roll_Number | ❌ Optional | Serial/Roll number | 1, 2, 3... |

### **✨ Flexible Column Order**
✅ **Columns can be in any order**  
✅ **Additional columns are ignored**  
✅ **Various header name variations supported**  
❌ **No fixed column positions required**

---

## 📋 Example Excel Files

### **Sample 1: Traditional Order**
```
| S.N | Class | Section | Name                  | Address              | Parents                | Contact    | Bus                   |
|-----|-------|---------|-----------------------|----------------------|------------------------|------------|-----------------------|
| 1   | 10    | Darwin  | Radha Kawar          | Rajpur-2,Materiya    | Shib Prasad Kawar     | 9869416392 | Gadhawa(Buddha Chowk) |
| 2   | 10    | Darwin  | Rajan Khatri Chhetri | Rapti-1,Bhalubang    | Chuman Sing K.C       | 9809557818 | Bhalubang             |
```

### **Sample 2: Different Order**
```
| Name                  | Class | Section | Contact    | Address              | Parents                | Bus                   |
|-----------------------|-------|---------|------------|----------------------|------------------------|-----------------------|
| Radha Kawar          | 10    | Darwin  | 9869416392 | Rajpur-2,Materiya    | Shib Prasad Kawar     | Gadhawa(Buddha Chowk) |
| Rajan Khatri Chhetri | 10    | Darwin  | 9809557818 | Rapti-1,Bhalubang    | Chuman Sing K.C       | Bhalubang             |
```

### **Sample 3: Alternative Header Names**
```
| Student Name          | Grade | Division | Phone Number | Address              | Parent Name            | Bus Route             |
|-----------------------|-------|----------|--------------|----------------------|------------------------|----------------------|
| Radha Kawar          | 10    | Darwin   | 9869416392   | Rajpur-2,Materiya    | Shib Prasad Kawar     | Gadhawa(Buddha Chowk) |
| Rajan Khatri Chhetri | 10    | Darwin   | 9809557818   | Rapti-1,Bhalubang    | Chuman Sing K.C       | Bhalubang             |
```

---

## 🎯 How Upload Works

### **Step 1: Prepare Your Excel**
1. Open Excel or Google Sheets
2. First row = Headers (Name, Roll No, Class, Section...)
3. Next rows = Student data
4. Save as `.xlsx` or `.xls`

### **Step 2: Upload in App**
1. Go to Students Screen for specific Class & Section
2. Click **"Choose Excel File"** button
3. Select your Excel file
4. App will:
   - ✅ Parse the file
   - ✅ Filter students for current class/section
   - ✅ **CLEAR existing students** in that section
   - ✅ Upload new data to Firestore
   - ✅ Display success message

### **Step 3: Take Photos**
1. Students list appears
2. Click camera icon for each student
3. Photo saved with filename: `Class_Section_RollNo_StudentName.jpg`

---

## 🔄 Re-uploading Behavior

**IMPORTANT:** When you re-upload an Excel file for a section:

✅ **All existing students in that section are DELETED**  
✅ **New students from Excel are added**  
✅ **Photos are NOT deleted from Cloudinary** (but link is removed from Firestore)

### **Example:**

**Before Upload:**
```
Firestore: Grade 10 - Section A
  - Student 1: John (with photo)
  - Student 2: Sarah (with photo)
  - Student 3: Raj (no photo)
```

**After Re-upload Excel:**
```
Excel contains:
  - John (same student)
  - Sarah (same student)
  - Mike (new student)
```

**Result:**
```
Firestore: Grade 10 - Section A
  - Student 1: John (no photo - need to retake!)
  - Student 2: Sarah (no photo - need to retake!)
  - Student 3: Mike (new - no photo)
```

**Raj is removed, existing photos links are cleared**

---

## ⚠️ Important Notes

### **1. Data Validation**
- Empty rows are skipped
- **Required fields:** Class, Section, Name (must have values)
- **Optional fields:** S.N, Address, Parents, Contact, Bus (can be empty)
- If S.N is empty, row number is used as Roll Number
- Column N is ignored
- Only students matching current class/section are imported

### **2. Class & Section Must Match**
When uploading to "Grade 10 - Section A" screen:
- ✅ Excel row with Class="Grade 10", Section="A" → Imported
- ❌ Excel row with Class="Grade 11", Section="A" → Skipped
- ❌ Excel row with Class="Grade 10", Section="B" → Skipped

### **3. Roll Number (S.N) Format**
- S.N column is used as Roll Number (if provided)
- ✅ Can be empty - row number will be used instead
- Can be numeric: `1`, `25`
- Will be stored as string: "1", "25"
- Used in photo filename: `10_darwin_1_radha_kawar.jpg`
- Example: If S.N is empty in row 5, roll number will be "5"

### **4. Case Sensitivity**
- Class and Section names are case-sensitive
- "Grade 10" ≠ "grade 10"
- "Section A" ≠ "Section a"

---

## 📦 Firestore Structure

After upload, data is stored as:

```
users/
  └── {userId}/
      └── classes/
          └── {className}/        e.g., "Grade 10"
              └── sections/
                  └── {sectionName}/    e.g., "A"
                      ├── metadata
                      │   ├── className: "Grade 10"
                      │   ├── sectionName: "A"
                      │   ├── studentCount: 25
                      │   └── lastUpdated: timestamp
                      └── students/
                          ├── {studentId1}/
                          │   ├── name: "John Doe"
                          │   ├── rollNo: "01"
                          │   ├── className: "Grade 10"
                          │   ├── section: "A"
                          │   ├── photoUrl: null or "https://..."
                          │   ├── address: "..."
                          │   ├── parentName: "..."
                          │   ├── contactNumber: "..."
                          │   ├── busRoute: "..."
                          │   ├── createdAt: timestamp
                          │   └── updatedAt: timestamp
                          ├── {studentId2}/
                          └── ...
```

---

## 🧪 Testing Your Excel File

### **Test Checklist:**

- [ ] First row has headers (Name, Roll No, Class, Section)
- [ ] All students have values for required columns
- [ ] Class names match exactly what's in your app
- [ ] Section names match exactly what's in your app
- [ ] No duplicate roll numbers in same class/section
- [ ] File saved as .xlsx or .xls format

### **Test Upload:**

1. Create small test file with 2-3 students
2. Upload to test section
3. Verify students appear in app
4. Take test photo to verify data is correct
5. Check Cloudinary filename format

---

## 💡 Tips

### **✅ Best Practices:**

1. **Use Template:** Create one master Excel template and copy for each section
2. **Backup:** Keep backup of Excel files before uploading
3. **Verify:** Double-check class/section names before upload
4. **Sort:** Sort by Roll No in Excel before uploading
5. **Clean Data:** Remove empty rows and clean up formatting

### **📊 Example Template:**

Download or create this template:

```excel
S.N | N | Class | Section | Name     | Address | Parents | Contact | Bus
1   |   | 10    | Darwin  | John Doe |         |         |         |
2   |   | 10    | Darwin  | Sarah    |         |         |         |
[Add more rows...]
```

---

## 🚨 Common Errors

### **Error: "No students found for this class/section"**
**Cause:** Class or Section name in Excel doesn't match screen  
**Solution:** Check spelling and case (Grade 10 vs grade 10)

### **Error: "No valid student data found"**
**Cause:** Missing required columns or all rows are invalid  
**Solution:** Check first 4 columns have data (Name, Roll No, Class, Section)

### **Error: "Failed to parse Excel file"**
**Cause:** File format issue or corrupted file  
**Solution:** Save as new .xlsx file, avoid special formatting

---

## 📞 Support

If upload fails:
1. Check error message
2. Verify Excel format matches template
3. Ensure required columns exist
4. Check for empty required fields
5. Try with smaller file (10 students) first

---

## 📝 Summary

| Aspect | Details |
|--------|---------|
| **Required Columns** | Name, Roll No, Class, Section |
| **Optional Columns** | Address, Parent Name, Contact, Bus Route |
| **File Format** | .xlsx or .xls |
| **Re-upload Behavior** | Clears existing, adds new |
| **Matching** | Exact match on Class & Section names |
| **Data Location** | `users/{userId}/classes/{class}/sections/{section}/students/` |

---

**Ready to upload? Make sure your Excel follows this format!** 📊✅

