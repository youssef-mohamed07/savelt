import PDFDocument from "pdfkit";
import { Transactions } from "../../DB/models/transactions.model.js";
import { AppError } from "../../utils/AppError.js";
import { catchError } from "../../utils/catchError.js";

// Export transactions to PDF
export const exportToPDF = catchError(async (req, res, next) => {
    const { startDate, endDate, categoryId } = req.query;

    const query = { user: req.user._id };

    if (startDate && endDate) {
        query.createdAt = {
            $gte: new Date(startDate),
            $lte: new Date(endDate)
        };
    }

    if (categoryId) {
        query.category = categoryId;
    }

    const transactions = await Transactions.find(query)
        .populate('category')
        .sort('-createdAt')
        .lean();

    if (transactions.length === 0) {
        return next(new AppError("No transactions found for export", 404));
    }

    // Create PDF
    const doc = new PDFDocument({ margin: 50 });

    // Set response headers
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename=transactions_${Date.now()}.pdf`);

    doc.pipe(res);

    // Title
    doc.fontSize(20).text('Transactions Report', { align: 'center' });
    doc.moveDown();

    // Date range
    if (startDate && endDate) {
        doc.fontSize(12).text(`Period: ${startDate} to ${endDate}`, { align: 'center' });
        doc.moveDown();
    }

    // Summary
    const totalAmount = transactions.reduce((sum, t) => sum + (t.price || 0), 0);
    doc.fontSize(14).text(`Total Transactions: ${transactions.length}`);
    doc.text(`Total Amount: ${totalAmount.toFixed(2)}`);
    doc.moveDown();

    // Table header
    doc.fontSize(10);
    const tableTop = doc.y;
    const col1 = 50;
    const col2 = 150;
    const col3 = 300;
    const col4 = 400;

    doc.text('Date', col1, tableTop, { bold: true });
    doc.text('Category', col2, tableTop);
    doc.text('Description', col3, tableTop);
    doc.text('Amount', col4, tableTop);

    doc.moveTo(50, tableTop + 15).lineTo(550, tableTop + 15).stroke();

    // Table rows
    let y = tableTop + 25;
    for (const transaction of transactions) {
        if (y > 700) {
            doc.addPage();
            y = 50;
        }

        const date = new Date(transaction.createdAt).toLocaleDateString();
        const category = transaction.category?.name || 'N/A';
        const description = transaction.text || 'N/A';
        const amount = transaction.price?.toFixed(2) || '0.00';

        doc.text(date, col1, y);
        doc.text(category.substring(0, 15), col2, y);
        doc.text(description.substring(0, 20), col3, y);
        doc.text(amount, col4, y);

        y += 20;
    }

    // Footer
    doc.fontSize(8).text(
        `Generated on ${new Date().toLocaleString()}`,
        50,
        doc.page.height - 50,
        { align: 'center' }
    );

    doc.end();
});

// Export transactions to CSV
export const exportToCSV = catchError(async (req, res, next) => {
    const { startDate, endDate, categoryId } = req.query;

    const query = { user: req.user._id };

    if (startDate && endDate) {
        query.createdAt = {
            $gte: new Date(startDate),
            $lte: new Date(endDate)
        };
    }

    if (categoryId) {
        query.category = categoryId;
    }

    const transactions = await Transactions.find(query)
        .populate('category')
        .sort('-createdAt')
        .lean();

    if (transactions.length === 0) {
        return next(new AppError("No transactions found for export", 404));
    }

    // Create CSV content
    const headers = ['Date', 'Category', 'Description', 'Amount', 'Type'];
    const rows = transactions.map(t => [
        new Date(t.createdAt).toISOString(),
        t.category?.name || 'N/A',
        `"${(t.text || '').replace(/"/g, '""')}"`,
        t.price || 0,
        t.voice_path ? 'Voice' : t.OCR_path ? 'OCR' : 'Text'
    ]);

    const csvContent = [
        headers.join(','),
        ...rows.map(row => row.join(','))
    ].join('\n');

    // Set response headers
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename=transactions_${Date.now()}.csv`);

    res.send(csvContent);
});

// Export transactions to JSON
export const exportToJSON = catchError(async (req, res, next) => {
    const { startDate, endDate, categoryId } = req.query;

    const query = { user: req.user._id };

    if (startDate && endDate) {
        query.createdAt = {
            $gte: new Date(startDate),
            $lte: new Date(endDate)
        };
    }

    if (categoryId) {
        query.category = categoryId;
    }

    const transactions = await Transactions.find(query)
        .populate('category')
        .sort('-createdAt')
        .lean();

    if (transactions.length === 0) {
        return next(new AppError("No transactions found for export", 404));
    }

    const exportData = {
        exportDate: new Date().toISOString(),
        totalTransactions: transactions.length,
        totalAmount: transactions.reduce((sum, t) => sum + (t.price || 0), 0),
        dateRange: startDate && endDate ? { startDate, endDate } : null,
        transactions: transactions.map(t => ({
            id: t._id,
            date: t.createdAt,
            category: t.category?.name || null,
            description: t.text || null,
            amount: t.price || 0,
            type: t.voice_path ? 'voice' : t.OCR_path ? 'ocr' : 'text'
        }))
    };

    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Content-Disposition', `attachment; filename=transactions_${Date.now()}.json`);

    res.json(exportData);
});
