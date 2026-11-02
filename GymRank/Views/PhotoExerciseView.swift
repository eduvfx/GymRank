//
//  PhotoExerciseView.swift
//  GymRank
//
//  Fotografia da máquina: classificador do sistema, mapeamento para o catálogo
//  e confirmação do utilizador antes de o exercício entrar no treino.
//

import SwiftUI
import PhotosUI
import UIKit

struct PhotoExerciseView: View {
    let onEscolher: (String, String, BodyPart) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var item: PhotosPickerItem?
    @State private var imagem: UIImage?
    @State private var sugestoes: [MachineSuggestion] = []
    @State private var aAnalisar = false
    @State private var mensagem = "Tira ou escolhe uma fotografia da máquina."
    @State private var mostrarCamera = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let imagem { foto(imagem) }
                    botoes
                    Text(mensagem).font(.caption).foregroundStyle(Color.gymMuted)
                    if aAnalisar { ProgressView().tint(Color.gymAccent) }
                    ForEach(sugestoes) { sugestao in
                        linha(sugestao)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Por fotografia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
            .onChange(of: item) { _, novo in
                guard let novo else { return }
                Task { await carregar(novo) }
            }
            .sheet(isPresented: $mostrarCamera) {
                CameraPicker { escolhida in
                    imagem = escolhida
                    Task { await analisar(escolhida) }
                }
            }
        }
    }

    private func foto(_ imagem: UIImage) -> some View {
        Image(uiImage: imagem)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 240)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var botoes: some View {
        HStack(spacing: 10) {
            PhotosPicker(selection: $item, matching: .images) {
                rotulo("Fototeca", icone: "photo.on.rectangle")
            }
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button { mostrarCamera = true } label: {
                    rotulo("Câmara", icone: "camera.fill")
                }
            }
        }
    }

    private func linha(_ sugestao: MachineSuggestion) -> some View {
        Button {
            onEscolher(sugestao.nome, sugestao.id, sugestao.parte)
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(sugestao.nome)
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                    Text("\(sugestao.parte.nome) · confiança \(Int(sugestao.confianca * 100))%")
                        .font(.caption2).foregroundStyle(Color.gymMuted)
                }
                Spacer()
                Image(systemName: "plus.circle").foregroundStyle(Color.gymAccent)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 11).fill(Color.gymCard))
        }
        .buttonStyle(.plain)
    }

    private func rotulo(_ texto: String, icone: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icone)
            Text(texto).font(.system(size: 14, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .background(RoundedRectangle(cornerRadius: 11).fill(Color.gymCard))
        .foregroundStyle(.white)
    }

    private func carregar(_ escolha: PhotosPickerItem) async {
        guard let dados = try? await escolha.loadTransferable(type: Data.self),
              let escolhida = UIImage(data: dados) else {
            mensagem = "Não consegui abrir a fotografia."
            return
        }
        imagem = escolhida
        await analisar(escolhida)
    }

    private func analisar(_ imagem: UIImage) async {
        aAnalisar = true
        let resultado = await MachineDetector.reconhecer(imagem: imagem)
        sugestoes = resultado
        aAnalisar = false
        mensagem = resultado.isEmpty
            ? "Não reconheci a máquina. Escolhe o exercício na lista."
            : "Confirma o exercício detetado:"
    }
}

/// Câmara (só existe em dispositivo real; no simulador o botão não aparece).
struct CameraPicker: UIViewControllerRepresentable {
    let onFoto: (UIImage) -> Void

    func makeCoordinator() -> Coordenador { Coordenador(onFoto: onFoto) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ picker: UIImagePickerController, context: Context) {}

    final class Coordenador: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onFoto: (UIImage) -> Void

        init(onFoto: @escaping (UIImage) -> Void) { self.onFoto = onFoto }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let escolhida = info[.originalImage] as? UIImage { onFoto(escolhida) }
            picker.dismiss(animated: true)
        }
    }
}
